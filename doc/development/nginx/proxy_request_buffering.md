---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Working with the bundled NGINX
---

## NGINX Proxy Request Buffering

[NGINXs `proxy_request_buffering`](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_request_buffering)
controls how incoming client requests are handled before forwarding to the
upstream server.

### Default Behavior (`on`)

By default, NGINX buffers the entire request body before forwarding to the backend.
Requests larger than [`client_body_buffer_size`](https://nginx.org/en/docs/http/ngx_http_core_module.html#client_body_buffer_size)
are written to temporary files, and once the full request was received, the request
will be forwarded as a whole to the backend.

This can help to reduce the amount of concurrent connections the backend has to keep
open and can protect the backend from slow clients.

### When disabled (`off`)

If `proxy_request_buffering` is disabled and a incoming requests exceeds the
`client_body_buffer_size` the request chunk will be immediately forwarded to
the backend.

This can help to optimize (large) streaming requests and reduces disk I/O
of NGINX.

### GitLab chart configuration

GitLab chart by default uses [NGINX Ingress](https://github.com/kubernetes/ingress-nginx) to
handle incoming traffic. By setting the `nginx.ingress.kubernetes.io/proxy-request-buffering`
annotation on a Ingress the NGINX `proxy_request_buffering` setting can be controlled.
This always impacts the whole Ingress and allows no filtering on a path level.

| Ingress / traffic type      | Status in Omnibus | Status in charts     | Owning Team                  | Target value                               | Comment |
|-----------------------------|-------------------|----------------------|------------------------------|--------------------------------------------|---------|
| Workhorse (Artifact API)    | `off` (filtered)  | not set (`on`)       | Shared                       | `off` expected to be more performant (large chunked artifact uploads) | Filtered in Omnibus since [MR 4516](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/4516). |
| Workhorse (Project Imports) | `off` (filtered)  | not set (`on`)       | Shared                       | `off` expected to be more performant (large chunked project uploads) | Setting `off` is expected to [improve performance](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6841). |
| Workhorse (Other Traffic)   | not set (`on`)    | not set (`on`)       | Shared                       | `on` expected to be more performant (many small requests) | |
| SSH over HTTP(S)            | `off` (filtered)  | not set (`on`)       | Shared                       | `off` functional requirement + improved disk performance  | Known issues [1](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2262 ) [2](https://gitlab.com/gitlab-org/gitlab/-/issues/454707), [3](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/31871) if proxy request buffering is off. |
| KAS                         | `on`              | not set (`on`)       | ~"group::environments"       | `on` expected to be more performant (many small requests) | [Omnibus configuration](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/04f29efeec94171e60a63eb06690a41f71e89ab1/files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-kas-http.conf.erb#L116) |
| GitLab Pages                | not set (`on`)    | not set (`on`)       | ~"group::knowledge"          | `on` expected to be more performant (many small requests) | [First assesment](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4512#note_2747102518) |
| Container Registry          | `off`             | `off` (configurable) | ~"group::container registry" | `off` functional requirement                              | [Known issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2848) if `proxy_request_buffering` is on. |
| MinIO                       | -                 | not set (`on`)       | ~group::operate              | unknown                                                   | Only bundled for PoC/demo environments. |

Note: [MR 4523](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4523) explores how to
configure `proxy_request_buffering` for some workhorse paths to match our Omnibus configuration.
