---
stage: none
group: unassigned
info: Temporary test page for the docs-i18n-fix-alert-boxes CI job. Delete before merge.
title: Page de test pour la correction des encadrés d'alerte
---

Cette page sert à vérifier le fonctionnement du job CI `docs-i18n-fix-alert-boxes`. À supprimer avant la fusion.

## Cas 1 : le corps est fusionné sur la ligne du marqueur

> [!note] La traduction automatique a placé le corps sur la même ligne que le marqueur.

## Cas 2 : la ligne du corps n'a pas le préfixe de citation

> [!warning]
Cette ligne n'a pas le préfixe de citation.

## Cas 3 : format correct (ne doit pas changer)

> [!note]
> Cette alerte est déjà au bon format.

## Cas 4 : indenté dans une liste

1. Description des étapes :

   > [!tip] Corps d'une alerte indentée.

## Cas 5 : autres types d'alerte

Alerte de type caution :

> [!caution] Cette action est irréversible.

Alerte de type tip :

> [!tip]
Nous recommandons de faire une sauvegarde au préalable.

Alerte de type flag :

> [!flag] Cette fonctionnalité est derrière un indicateur.

Alerte de type disclaimer :

> [!disclaimer]
Vérifiez la documentation avant de modifier la configuration.

Alerte de type warning :

> [!warning] Ces informations sont fournies à titre indicatif.

## Cas 6 : marqueur en majuscules

> [!NOTE] Les marqueurs en majuscules sont aussi traités.

## Cas 7 : ligne vide après le marqueur (ne doit pas changer)

> [!note]

Paragraphe après une ligne vide.
