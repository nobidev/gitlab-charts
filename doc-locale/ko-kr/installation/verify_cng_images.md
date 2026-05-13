---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CNG 이미지 무결성 검증
---

CNG 이미지가 레지스트리로 푸시된 후 변조되지 않도록 보장하기 위해 해당 다이제스트는 [`cosign`](https://github.com/sigstore/cosign)를 사용하여 서명됩니다. `cosign`는 ECDSA-P256 키와 SHA256 해시를 사용합니다. 키는 PEM 인코딩 PKCS8 형식으로 저장됩니다.

이러한 다이제스트는 다음에 설명된 대로 `cosign verify` 명령을 사용하여 검증할 수 있습니다:

> [!note] 이미지는 개인 키를 사용하여 서명되며 해당 공개 키를 사용하여 로컬에서만 검증할 수 있습니다. GitLab.com OIDC 제공자를 사용한 키 없는 서명/검증으로의 이동이 [이슈 638](https://gitlab.com/gitlab-org/build/CNG/-/issues/638)에서 논의 중입니다.

1. <https://charts.gitlab.io/cosign.pub>에서 서명에 사용된 공개 키를 다운로드합니다:

   ```shell
   wget https://charts.gitlab.io/cosign.pub
   ```

1. CNG 이미지를 검증합니다:

   ```shell
   $ cosign verify --key cosign.pub registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee:v16.9.0 | jq -r

   Verification for registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee:v16.9.0 --
   The following checks were performed on each of these signatures:
     - The cosign claims were validated
     - Existence of the claims in the transparency log was verified offline
     - The signatures were verified against the specified public key
   [
     {
       "critical": {
         "identity": {
           "docker-reference": "dev.gitlab.org:5005/gitlab/charts/components/images/gitlab-workhorse-ee"
         },
         "image": {
           "docker-manifest-digest": "sha256:218a67cc46b49ba0563dbdc83618bf11fa5453577a4aa75475823e315952ea79"
         },
         "type": "cosign container image signature"
       },
       "optional": {
         "Bundle": {
           "SignedEntryTimestamp": "MEUCIQCDj2Ffe8Qll9clqAKoBA8wTwg2NrzMLvpVMkw61qdhmAIgQgLYCT7IdGwVEp5UrQjN67Zt9CTATQpi08+CrGgqnxw=",
           "Payload": {
             "body": "eyJhcGlWZXJzaW9uIjoiMC4wLjEiLCJraW5kIjoiaGFzaGVkcmVrb3JkIiwic3BlYyI6eyJkYXRhIjp7Imhhc2giOnsiYWxnb3JpdGhtIjoic2hhMjU2IiwidmFsdWUiOiI4Mzg1Y2YyYzI0MjI5ZjFhYzk2MTU1ZGU3YzM3ZjcyZmQzOTczYTgwZGIyMjNmNDUwZjlhNGMxNjRmZDIyNmUzIn19LCJzaWduYXR1cmUiOnsiY29udGVudCI6Ik1FUUNJRVpjcENpRFJ5V1FuT25jRGtmUEtaTnRPc0s4dW9YeFJqMEcrTnZ1VzRwS0FpQThEK2YyWVRtQ2Z3MVFqK0doQmlVb0tFQVA4dE5MWDZOYk1kczFUQ1JJR0E9PSIsInB1YmxpY0tleSI6eyJjb250ZW50IjoiTFMwdExTMUNSVWRKVGlCUVZVSk1TVU1nUzBWWkxTMHRMUzBLVFVacmQwVjNXVWhMYjFwSmVtb3dRMEZSV1VsTGIxcEplbW93UkVGUlkwUlJaMEZGYnpGQk5tbEZjbXhrSzFoRU5WSTBiVXRNU1VGNU4wVXhOMlV3WXdwV1VWSldlVEpoTmpoSlRESklSaXRXV1VKeWFqRkpjbHAyT0ZsdU5UUTVaU3RUUVRVeVpVZHZLMEpIU1RWSWJVeGxVbXR2Wm5Ob1MxaG5QVDBLTFMwdExTMUZUa1FnVUZWQ1RFbERJRXRGV1MwdExTMHRDZz09In19fX0=",
             "integratedTime": 1707955615,
             "logIndex": 71468664,
             "logID": "c0d23d6ad406973f9559f3ba2d1ca01f84147d8ffc5b8445c224f98b9591801d"
           }
         }
       }
     }
   ]
   ```
