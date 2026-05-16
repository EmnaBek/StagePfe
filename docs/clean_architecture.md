# Clean Architecture du projet

Ce projet utilise une organisation par fonctionnalité (`features`) et applique la
séparation suivante pour les écrans qui contiennent de la logique métier :

```text
lib/features/<feature>/
  domain/        # Entités, contrats de repositories, règles métier, use cases
  data/          # Datasources techniques et implémentations des repositories
  presentation/  # Widgets, pages, controllers/notifiers UI
```

## Règles à respecter

1. La couche `presentation` ne doit pas appeler directement `http`,
   `MethodChannel`, SQL, SharedPreferences ou un état global technique.
2. La couche `presentation` appelle un use case via `AppInjection` ou via un
   controller/notifier injecté.
3. La couche `domain` ne doit pas importer Flutter, `http`, `mobile_scanner` ou
   des datasources techniques.
4. La couche `data` adapte les APIs externes vers les contrats définis dans
   `domain`.
5. Les dépendances vont vers l'intérieur : `presentation -> domain` et
   `data -> domain`. Le domaine ne dépend pas de `presentation` ou `data`.

## Exemple appliqué : validation QR

La validation QR est maintenant structurée comme suit :

```text
lib/features/validation/
  domain/
    entities/
    repositories/
    services/
    usecases/
  data/
    datasources/
    repositories/
  presentation/
    pages/
```

Le widget de scan QR se limite à :

- lire la valeur détectée par la caméra ;
- appeler `ValidateQrToken` via `AppInjection` ;
- afficher l'état de l'opération ;
- naviguer vers le dashboard quand le use case retourne `shouldOpenDashboard`.

Le parsing du QR, le décodage JWT, la sauvegarde de session et la validation API
sont sortis de la page et placés dans les couches `domain` et `data`.

## Étapes pour continuer la migration

1. Créer un controller/notifier par page complexe (`ReferentielPage`,
   `HospitalisationPage`, pages de caisse) pour sortir l'état et les actions UI
   des widgets.
2. Remplacer les accès directs à `UserSession` dans les pages et repositories
   par une abstraction injectée.
3. Déplacer le parsing MRZ/carte et les conversions d'image hors des pages vers
   des services de domaine ou use cases dédiés.
4. Ajouter des tests unitaires pour chaque service de domaine et chaque use case.
5. Garder les widgets concentrés sur l'affichage, les formulaires et la
   navigation uniquement.
