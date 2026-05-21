---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 의사 결정
---

이 저장소에 대한 변경 사항은 먼저 [병합 요청 워크플로우](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/merge_requests/)를 사용하여 검토한 후 프로젝트 유지관리자가 병합합니다.

아키텍처 결정 사항(예: [아키텍처](architecture.md) 또는 [결정](decisions.md) 페이지에 나타날 사항)은 프로젝트의 선임 기술 리더십 검토가 필요합니다. 선임 기술 리더십은 프로젝트를 담당하는 팀의 엔지니어링 매니저와 [아키텍처 핸드북](https://handbook.gitlab.com/handbook/engineering/architecture/#architecture-as-a-practice-is-everyones-responsibility)에서 언급한 해당 팀의 Staff+ 리더십, 그리고 프로젝트에 특정된 목표를 중심으로 구성된 현재 워킹 그룹의 개인들입니다.

## 유지관리자 {#maintainers}

프로젝트 유지관리자는 [GitLab 프로젝트 페이지](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab-chart) 에서 찾을 수 있으며, [검토 워크로드 대시보드](https://gitlab-org.gitlab.io/gitlab-roulette/?currentProject=gitlab-chart&mode=hide)를 사용하여 찾을 수도 있습니다.

유지관리자는 자신의 도메인 내에서 변경 사항을 병합할 책임이 있으며, 전체 프로젝트를 이해하고 변경 사항이 자신의 전문 영역 외의 영역에 미칠 수 있는 영향을 파악해야 합니다.

검토자는 모든 유지관리자에게 할당할 수 있으며, 유지관리자는 자신의 범위에 해당되지 않는 경우 적절한 도메인 전문가를 참여시킵니다.

자신의 전문 영역을 계속 확장하기 위해 유지관리자는 자신의 도메인 외의 변경 사항을 병합할 수 있는 권한이 있지만, 다음을 제외하고는 **highly confident**할 수 있어야 합니다:

- 변경 사항을 나중에 되돌릴 수 없음
- 변경 사항이 따라야 할 확립된 프로세스가 있음(JiHu 검토, 보안, 법률/라이선스 변경)
- 변경 사항이 명확하게 아키텍처 결정을 요구함

긴급한 변경이 필요한 경우, 유지관리자는 행동을 선호해야 하며, 결정이 나중에 되돌릴 수 있고 알려진 프로젝트 프로세스 요구사항을 준수하는 한 결정을 내릴 수 있습니다.

### 의존성 유지관리자 {#dependency-maintainers}

의존성 유지관리자는 일반 유지관리자와 동일한 책임을 가지지만, 병합 능력은 특정 도메인에 대한 의존성 버전 관리와 관련된 변경 사항으로만 엄격하게 범위가 지정됩니다. 의존성 버전 관리 외에 다른 변경 사항이 병합 요청에 있으면, 유지관리자 검토를 수행하기 위해 일반 유지관리자가 필요합니다.

모든 변경 사항은 작동하는 차트를 만들어야 하며, 의존성 버전의 변경 영향을 의존성 유지관리자가 완전히 이해해야 합니다. 이미 차트 검토자인 개인들은 의존성 유지관리자가 될 수 있는 좋은 후보입니다.

| 사용자 이름         | 범위 |
|------------------|-------|
| `@DylanGriffith` | `gitlab-zoekt` |
| `@dgruzd`        | `gitlab-zoekt` |
| `@terrichu`      | `gitlab-zoekt` |
| `@johnmason`     | `gitlab-zoekt` |

## 프로젝트 리더십 {#project-leadership}

| 사용자 이름      | 역할 |
|---------------|------|
| `@WarheadsSE` | 스태프 엔지니어, 배포 관리 |
| `@twk3`       | 엔지니어링 매니저, 배포 빌드 |
| `@ayufan`     | 이사급 엔지니어, 역량 강화 |
| `@stanhu`     | 엔지니어링 펠로우 |
