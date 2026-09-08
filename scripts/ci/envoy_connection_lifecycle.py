#!/usr/bin/env python3
"""Exercise HTTP keep-alive connections through the k3d Envoy Gateway."""

import http.client
import os
import re
import subprocess
import sys
import threading
import time
import urllib.request
from pathlib import Path


CONNECTIONS = 24
CYCLES = 3
IDLE_SECONDS = 5
METRIC = "envoy_cluster_upstream_cx_active"
OVERFLOW_METRIC = "envoy_cluster_upstream_cx_overflow"
ARTIFACT_DIR = Path("envoy-connection-lifecycle")


def run(*args):
    return subprocess.run(args, check=True, text=True, capture_output=True).stdout


def gateway_name():
    return run(
        "kubectl", "get", "gateway", "-n", os.environ["NAMESPACE"],
        "-o", "jsonpath={.items[0].metadata.name}"
    ).strip()


def proxy_pod(gateway):
    return run(
        "kubectl", "get", "pods", "-n", os.environ["NAMESPACE"],
        "-l", f"gateway.envoyproxy.io/owning-gateway-name={gateway}",
        "-o", "jsonpath={.items[0].metadata.name}"
    ).strip()


def start_metrics_port_forward(pod):
    process = subprocess.Popen(
        ["kubectl", "port-forward", "-n", os.environ["NAMESPACE"], pod, "19001:19001"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
    )
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f"Envoy metrics port-forward exited: {process.stderr.read()}")
        try:
            with urllib.request.urlopen("http://127.0.0.1:19001/stats/prometheus", timeout=2) as response:
                return process, response.read().decode()
        except OSError:
            time.sleep(1)
    process.terminate()
    raise RuntimeError("Timed out waiting for the Envoy metrics port-forward")


def stop_port_forward(process):
    if process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()


def metric_value(metrics, metric, cluster=None):
    values = []
    for labels, value in re.findall(rf"^{metric}(\{{[^}}]*\}})?\s+([0-9.eE+-]+)$", metrics, re.MULTILINE):
        if cluster is None or f'envoy_cluster_name="{cluster}"' in (labels or ""):
            values.append(float(value))
    return sum(values)


def active_connections(metrics, phase, cluster):
    (ARTIFACT_DIR / f"envoy-metrics-{phase}.prometheus").write_text(metrics)
    return metric_value(metrics, METRIC, cluster)


def request(connection):
    connection.request("GET", "/users/sign_in", headers={"Host": os.environ["GITLAB_URL"]})
    response = connection.getresponse()
    response.read()
    if response.status != 200:
        raise RuntimeError(f"GET /users/sign_in returned HTTP {response.status}, expected 200")


def read_metrics():
    with urllib.request.urlopen("http://127.0.0.1:19001/stats/prometheus", timeout=10) as response:
        return response.read().decode()


def read_active_connections(phase, cluster):
    return active_connections(read_metrics(), phase, cluster)


def request_burst(connections):
    errors = []
    start = threading.Barrier(len(connections))

    def send_request(connection):
        try:
            start.wait()
            request(connection)
        except Exception as error:
            errors.append(error)

    threads = [threading.Thread(target=send_request, args=(connection,)) for connection in connections]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    if errors:
        raise errors[0]


def wait_for_drain(baseline, cluster):
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        current = read_active_connections("drain", cluster)
        print(f"Active upstream connections after close: {current}")
        if current <= baseline:
            return
        time.sleep(2)
    raise RuntimeError(f"Upstream connections did not drain to baseline {baseline}")


def main():
    for name in ("GITLAB_URL", "NAMESPACE"):
        if not os.environ.get(name):
            raise RuntimeError(f"{name} must be set")

    ARTIFACT_DIR.mkdir(exist_ok=True)
    gateway = gateway_name()
    pod = proxy_pod(gateway)
    print(f"Gateway: {gateway}; Envoy proxy pod: {pod}")

    port_forward, metrics = start_metrics_port_forward(pod)
    try:
        clusters = re.findall(r'envoy_cluster_upstream_cx_active\{[^}]*envoy_cluster_name="([^"]*webservice[^"]*)"', metrics)
        if not clusters:
            raise RuntimeError("Could not find an Envoy upstream cluster for webservice")
        cluster = clusters[0]
        print(f"Webservice upstream cluster: {cluster}")
        baseline = active_connections(metrics, "baseline", cluster)
        print(f"Baseline active upstream connections: {baseline}")
        connections = [
            http.client.HTTPConnection(os.environ["GITLAB_URL"], 80, timeout=30)
            for _ in range(CONNECTIONS)
        ]
        for cycle in range(1, CYCLES + 1):
            request_burst(connections)
            current = read_active_connections(f"cycle-{cycle}", cluster)
            print(f"Cycle {cycle}: active upstream connections: {current}")
            if current <= baseline:
                raise RuntimeError(
                    f"Cycle {cycle}: active upstream connections rose to {current}, "
                    f"expected more than baseline {baseline}"
                )
            time.sleep(IDLE_SECONDS)
            idle = read_active_connections(f"cycle-{cycle}-idle", cluster)
            print(f"Cycle {cycle} after {IDLE_SECONDS}s idle: active upstream connections: {idle}")
            if idle <= baseline:
                raise RuntimeError(
                    f"Cycle {cycle}: upstream connections returned to {idle} during the idle period, "
                    f"expected more than baseline {baseline} while client connections remain open"
                )
    finally:
        for connection in locals().get("connections", []):
            connection.close()
        stop_port_forward(port_forward)

    port_forward, _ = start_metrics_port_forward(pod)
    try:
        wait_for_drain(baseline, cluster)
        metrics = read_metrics()
        overflow = metric_value(metrics, OVERFLOW_METRIC, cluster)
        (ARTIFACT_DIR / "envoy-metrics-final.prometheus").write_text(metrics)
        if overflow != 0:
            raise RuntimeError(f"Envoy rejected {overflow} webservice upstream connections")
    finally:
        stop_port_forward(port_forward)
    print("Envoy upstream connections returned to baseline after persistent client connections closed.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Envoy connection-lifecycle check failed: {error}", file=sys.stderr)
        sys.exit(1)
