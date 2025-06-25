---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CNGイメージの整合性の検証
---

CNGイメージが[`cosign`](https://github.com/sigstore/cosign)を使用してdigestに署名し、レジストリにプッシュされた後で改ざんされないようにするために、`cosign`はECDSA-P256キーとSHA256ハッシュを使用します。キーはPEMエンコードされたPKCS8形式で格納されます。

これらのdigestは、以下に示すように`cosign verify`コマンドを使用してVerifyできます。

{{< alert type="note" >}}

イメージは秘密キーを使用して署名されており、対応する公開キーを使用してローカルでVerifyすることのみが可能です。[イシュー638](https://gitlab.com/gitlab-org/build/CNG/-/issues/638)で、GitLab.com OIDCプロバイダーを使用したキーレス署名/Verifyへの移行について議論されています。

{{< /alert >}}

1. [https://charts.gitlab.io/cosign.pub](https://charts.gitlab.io/cosign.pub)から署名に使用される公開キーをダウンロードします。

   ```shell
   wget https://charts.gitlab.io/cosign.pub
   ```

1. CNGイメージをVerifyします。

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
