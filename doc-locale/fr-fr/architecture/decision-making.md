---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Prise de décision
---

Les modifications apportées à ce dépôt sont d'abord examinées à l'aide du [flux de travail des merge requests](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/merge_requests/), puis fusionnées par les mainteneurs du projet.

Les décisions architecturales (telles que celles qui apparaîtraient sur les pages [architecture](architecture.md) ou [decisions](decisions.md)) nécessitent l'examen de la direction technique senior du projet. La direction technique senior est constituée d'individus identifiés par le responsable de l'ingénierie de l'équipe responsable du projet, ainsi que par les membres Staff+ de cette équipe mentionnés dans le [handbook d'architecture](https://handbook.gitlab.com/handbook/engineering/architecture/#architecture-as-a-practice-is-everyones-responsibility) et par tout groupe de travail actuel formé autour d'un objectif spécifique au projet.

## Mainteneurs {#maintainers}

Les mainteneurs du projet peuvent être trouvés sur la [page des projets GitLab](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab-chart) , ou localisés à l'aide du [tableau de bord de charge de relecture](https://gitlab-org.gitlab.io/gitlab-roulette/?currentProject=gitlab-chart&mode=hide).

Les mainteneurs sont responsables de la fusion des modifications dans leur domaine, et doivent avoir une compréhension globale du projet et de la façon dont les modifications peuvent impacter des domaines en dehors de leur expertise.

Les relecteurs peuvent assigner à n'importe quel mainteneur, et le mainteneur fera appel à l'expert du domaine approprié si cela ne relève pas de ses propres compétences.

Afin de continuer à élargir leur expertise, les mainteneurs sont habilités à fusionner des modifications en dehors de leur domaine, à condition qu'ils en soient **highly confident**, sauf si :

- La modification ne peut pas être annulée ultérieurement
- La modification suit un processus établi qui doit être respecté (revue JiHu, sécurité, modifications légales/de licence)
- La modification nécessite clairement une décision architecturale

Lorsque des modifications urgentes sont nécessaires, les mainteneurs doivent avoir un biais pour l'action, et peuvent prendre des décisions à condition que celles-ci soient ultérieurement réversibles et conformes aux exigences connues du processus du projet.

### Mainteneurs de dépendances {#dependency-maintainers}

Un mainteneur de dépendances a les mêmes responsabilités qu'un mainteneur ordinaire, mais la capacité de fusion est strictement limitée aux modifications liées à la gestion des versions de dépendances pour un domaine spécifique. Si une modification autre qu'un versionnage de dépendance est présente dans la merge request, un mainteneur ordinaire est requis pour effectuer la revue de mainteneur.

Toutes les modifications doivent aboutir à un chart fonctionnel, et l'impact de la modification sur les versions des dépendances doit être entièrement compris par le mainteneur de dépendances. Les individus qui sont déjà des relecteurs de chart sont de bons candidats pour devenir mainteneurs de dépendances.

| Nom d'utilisateur         | Portée |
|------------------|-------|
| `@DylanGriffith` | `gitlab-zoekt` |
| `@dgruzd`        | `gitlab-zoekt` |
| `@terrichu`      | `gitlab-zoekt` |
| `@johnmason`     | `gitlab-zoekt` |

## Direction du projet {#project-leadership}

| Nom d'utilisateur      | Rôle |
|---------------|------|
| `@WarheadsSE` | Staff Engineer, Distribution Deploy |
| `@twk3`       | Engineering Manager, Distribution Build |
| `@ayufan`     | Distinguished Engineer, Enablement |
| `@stanhu`     | Engineering Fellow |
