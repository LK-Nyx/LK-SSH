# Design System Foundation — Spec

**Date :** 2026-04-28
**Statut :** brainstorm validé
**Sous-projet :** premier livrable de la pass UX/UI globale (foundation-first)

---

## 1. Contexte

Phase 1 (auth & host trust) tout juste mergée sur `main`. L'app est complète fonctionnellement (snippets, terminal 60fps, multi-keys, host TOFU, modes A/D). La pass UX/UI démarre maintenant et a été découpée en sous-projets.

Stratégie retenue : **foundation-first**. On définit d'abord un design system (tokens + primitives) ; les sous-projets suivants s'occuperont du refactor screen par screen contre ce système.

Direction aesthetic retenue : **matrix raffiné**. On ne change pas l'identité (noir + vert), on la pose proprement avec hiérarchie, structure, et typographie sérieuse. Décision prise en l'absence du dev principal : zéro risque de pivot stylistique.

## 2. Scope du sous-projet

**Livrable** : tokens consommables + 5 widgets primitifs.

**Inclus :**
- Tokens Dart : couleurs, typographie, espacement, radius, motion, focus glow.
- Une famille mono embarquée : JetBrains Mono.
- 5 primitives : `AppButton`, `AppTextField`, `AppTile`, `AppCard`, `AppSheet`.
- Extension `ThemeData` qui mappe les tokens vers Material 3 (pour que `Theme.of(context)` continue de marcher pour les widgets natifs).
- Tests widget pour chaque primitive (variantes + états).

**Non inclus** (deferred à des sous-projets ultérieurs) :
- Refactor des écrans existants pour consommer les primitives.
- États empty/loading/error sur les écrans.
- Animations spécifiques par écran.
- Onboarding & flows.

## 3. Tokens

### 3.1 Palette

#### Surfaces (5 tiers, du plus profond au plus haut)

| Token | Valeur | Usage |
|---|---|---|
| `bg/canvas` | `#0A0A0A` | Page background (Scaffold) |
| `bg/surface` | `#121212` | Cards, list backgrounds |
| `bg/raised` | `#1A1A1A` | Selected rows, hover, sheets |
| `border/subtle` | `#1F1F1F` | Hairlines, list dividers |
| `border/default` | `#2A2A2A` | Inputs, cards outline au repos |

#### Contenu (texte, icônes)

| Token | Valeur | Usage |
|---|---|---|
| `content/primary` | `#E8FFE8` | Titres, valeurs courantes (blanc-vert, pas pur blanc) |
| `content/secondary` | `#A8C8A8` | Labels, meta |
| `content/muted` | `#5F8F5F` | Timestamps, hints |
| `content/disabled` | `#3A4A3A` | Texte grisé |

#### Accent (action / focus)

| Token | Valeur | Usage |
|---|---|---|
| `accent/primary` | `#3FCB3F` | FAB, boutons primaires, borders focus, état actif |
| `accent/pressed` | `#2A8A2A` | État pressed des actions accent |
| `accent/neon` | `#00FF41` | Base du glow signature (pas un fill direct) |

#### États sémantiques

| Token | Valeur | Usage |
|---|---|---|
| `state/success` | `#3FCB3F` | = `accent/primary`, distinguer par icône check |
| `state/warning` | `#F2B84B` | Confirm dangereux, host changed |
| `state/error` | `#FF5C5C` | Échecs auth, validation form |
| `state/info` | `#5FB8E8` | Tips, neutres |

#### Focus glow

**Règle :** le border d'un élément focusé reste sa couleur "calme et lisible" ; le glow utilise la **version neon** de la même teinte. Cohérent à travers tous les états.

| Token | Valeur | Blur |
|---|---|---|
| `focusGlow/accent` | `rgba(0, 255, 65, 0.35)` | 12px |
| `focusGlow/error` | `rgba(255, 0, 64, 0.60)` | 16px |
| `focusGlow/warning` | `rgba(255, 170, 0, 0.50)` | 14px |
| `focusGlow/info` | `rgba(0, 200, 255, 0.40)` | 14px |

API : `AppColors.focusGlow(state)` retourne un `BoxShadow` paramétré par `state` ; les primitives composent `border + focusGlow(currentState)` sans hardcoder le glow.

### 3.2 Typographie

**Stratégie : mixte sans/mono.**

- **Sans-serif** (chrome humain) : système Android (Roboto), zéro asset.
- **Mono** (data machine) : **JetBrains Mono** embarquée (~50KB woff/ttf via `pubspec.yaml`).

Rôle :
- Sans → titres, labels, descriptions, boutons.
- Mono → hosts, IPs, ports, fingerprints, paths, snippets, terminal.

Le contraste sans/mono crée l'identité "outil tech" sans alourdir la lecture des écrans formulaires.

#### Échelle (7 niveaux)

| Token | Famille | Taille | Poids | Line-height | Usage |
|---|---|---|---|---|---|
| `type/display` | sans | 24 | 700 | 1.20 | Empty states, héro (rare) |
| `type/title` | sans | 20 | 600 | 1.25 | Titres d'écran, AppBar |
| `type/heading` | sans | 16 | 600 | 1.30 | Titres de section, group labels |
| `type/body` | sans | 14 | 400 | 1.45 | Texte courant, valeurs primaires |
| `type/label` | sans | 12 | 500 | 1.40 | Labels d'input (combinés `uppercase` + `letter-spacing 0.08em`) |
| `type/caption` | sans | 11 | 400 | 1.40 | Timestamps, hints, helper text |
| `type/micro` | sans | 10 | 600 | 1.20 | Tags, badges, status pills (`uppercase` + `letter-spacing 0.10em`) |

Variantes mono parallèles pour les valeurs techniques :

| Token | Taille | Usage |
|---|---|---|
| `mono/body` | 14 | Terminal, snippets en ligne |
| `mono/code` | 12 | Fingerprints, IDs, hashes |
| `mono/data` | 11 | IPs, ports, valeurs inline dans listes |

### 3.3 Espacement

Grille **4pt** (compatible dp Android).

| Token | dp | Usage typique |
|---|---|---|
| `space/xs` | 4 | Entre icône et texte |
| `space/sm` | 8 | Entre éléments d'une row |
| `space/md` | 12 | Padding vertical bouton |
| `space/lg` | 16 | Padding horizontal écran |
| `space/xl` | 20 | — |
| `space/2xl` | 24 | Entre sections |
| `space/3xl` | 32 | Avant titre principal |
| `space/4xl` | 40 | — |
| `space/5xl` | 48 | — |
| `space/6xl` | 64 | Empty state height |

### 3.4 Radius

| Token | dp | Usage |
|---|---|---|
| `radius/sharp` | 0 | Terminal, hairlines |
| `radius/sm` | 4 | Badges, chips, tags |
| `radius/md` | 8 | Boutons, inputs |
| `radius/lg` | 12 | Cards |
| `radius/sheet` | 16 (top only) | Bottom sheets |
| `radius/full` | ∞ | FAB, avatars, status dots |

### 3.5 Bordures

Convention : **slash `/` = color token**, **dot `.` = preset** (width + color combinés). Les color tokens `border/subtle` et `border/default` (déclarés en 3.1) sont consommés par les presets ci-dessous.

| Preset | Width | Couleur | Usage |
|---|---|---|---|
| `border.hair` | 1 dp | `border/subtle` | Dividers, séparateurs subtils |
| `border.standard` | 1 dp | `border/default` | Cards, inputs au repos |
| `border.focus` | 1 dp | `accent/primary` | Inputs/cards en focus (la couleur change, pas la width) |
| `border.activeMarker` | 3 dp `borderLeft` | `accent/primary` | Marker de gauche pour `AppTile.isActive` |

**Élévation : pas d'ombres CSS/Flutter.** Sur fond noir elles rendent dégueu. Hiérarchie via les tiers de surface (canvas → surface → raised). Seule exception : le focus glow neon (cf. `focusGlow/*`).

**Note Flutter :** les valeurs `blur 12/14/16px` des `focusGlow/*` correspondent à `blurRadius` du `BoxShadow`. Pas de `spreadRadius`.

### 3.6 Motion

#### Durées

| Token | ms | Usage |
|---|---|---|
| `duration/instant` | 100 | Press feedback, ripple |
| `duration/fast` | 150 | Hover, focus ring, fade |
| `duration/base` | 200 | Expand/collapse, reveal — défaut |
| `duration/slow` | 300 | Bottom sheet enter, page push |
| `duration/lazy` | 500 | Grandes révélations (rare) |

#### Courbes

| Token | Flutter | Cubic | Usage |
|---|---|---|---|
| `curve/standard` | `Curves.easeInOut` | (0.4, 0, 0.2, 1) | Défaut, transitions symétriques |
| `curve/emphasized` | `Curves.easeOutCubic` | (0.2, 0, 0, 1) | Page push, sheet enter |
| `curve/decelerate` | `Curves.easeOut` | (0, 0, 0.2, 1) | Éléments qui apparaissent |
| `curve/accelerate` | `Curves.easeIn` | (0.4, 0, 1, 1) | Éléments qui sortent |

#### Patterns documentés

- **Page push** — slide horizontal · 300ms · emphasized.
- **Bottom sheet enter** — slide vertical from bottom · 300ms · emphasized.
- **Bottom sheet exit** — slide vertical to bottom · 200ms · accelerate.
- **Button press** — scale 1 → 0.96 · 100ms · standard.
- **List row hover/active** — bg fade + 4dp slide horizontal · 200ms · standard.
- **Input focus** — border + glow · 150ms · decelerate.
- **Snackbar / toast** — slide+fade in 200ms / out 150ms accelerate · hold 4s.
- **Empty state reveal** — fade + rise 8dp · 250ms · decelerate.

## 4. Primitives

Conventions communes :
- Tous les widgets vivent dans `lib/presentation/design/`.
- Préfixe `App*` pour distinguer des widgets Material/Cupertino.
- API minimale, sans paramètre cosmétique optionnel "padding/color/etc." — le système décide.

### 4.1 AppButton

```dart
AppButton(
  label: 'Connect',
  variant: ButtonVariant.primary,    // .primary | .secondary | .ghost | .danger
  onPressed: () { ... },
  leadingIcon: Icons.login,           // optionnel
  isLoading: false,                   // remplace le label par un spinner accent
);
```

**Variantes :**
| Variant | Background | Text | Border | Usage |
|---|---|---|---|---|
| `primary` | `accent/primary` | `bg/canvas` | — | Action principale (Connect, Save) |
| `secondary` | transparent | `accent/primary` | 1px `accent/primary` | Action secondaire (Cancel d'un destructif) |
| `ghost` | transparent | `content/secondary` | — | Action tertiaire, "Edit" inline |
| `danger` | transparent | `state/error` | 1px `state/error` | Action destructive (Reject host, Delete) |

**États :** `rest`, `hover` (web/desktop only — Android = N/A), `pressed` (scale 0.96 · 100ms), `disabled` (opacity 0.5 + bg `bg/raised`), `loading` (spinner remplace label, `onPressed` ignoré).

**Padding :** `space/md` vertical, `space/lg` horizontal. Min-height 40dp.
**Radius :** `radius/md` (8).
**Type :** `type/body` (sans 14/600).

### 4.2 AppTextField

```dart
AppTextField(
  label: 'Host',
  hint: 'Domaine ou IP',
  errorText: validation.error,         // null si pas d'erreur
  controller: hostController,
  obscureText: false,
  multiline: false,
  mono: true,                           // active la police mono pour la valeur (host, IP, fingerprint)
  prefixIcon: Icons.dns,                // optionnel
);
```

**Layout vertical :**
1. Label (`type/label`, uppercase, tracking 0.08em, color `content/secondary`).
2. Input (border `border.standard`, radius `radius/md`, padding `space/md` `space/md`).
3. Hint OU errorText (`type/caption`, color `content/muted` ou `state/error`).

**États (la width reste 1dp, seule la couleur change) :**
- `rest` — `border.standard`.
- `focus` — `border.focus` + `focusGlow/accent`.
- `error` (sans focus) — border 1dp `state/error`.
- `error + focus` — border 1dp `state/error` + `focusGlow/error` (rouge neon punchy).
- `disabled` — opacity 0.5, `border.hair`.

**Police de la value :** `type/body` (sans) si `mono: false`, `mono/body` si `mono: true`.

### 4.3 AppTile

Row de liste réutilisable. Remplace `ListTile` Material partout (server list, snippet list, keys list, settings rows).

```dart
AppTile(
  title: 'staging',
  subtitle: 'deploy@10.0.0.5:22',
  leading: AppTileLeading.text('SSH'),  // ou AppTileLeading.icon(Icons.dns)
  trailing: AppTileTrailing.chevron(),  // ou .indicator(state/success), .none
  badge: TileBadge(label: 'HOST CHANGED', tone: BadgeTone.warning),  // optionnel
  isActive: false,                      // border-left accent + bg raised
  onTap: () { ... },
  onLongPress: () { ... },              // optionnel (delete / edit menu)
);
```

**Layout :** `space/lg` horizontal, `space/md` vertical, gap `space/md`. `border.hair` bottom (les tiles font ensemble une liste continue, pas des cards séparées).

**Subtitle :** `mono/data` par défaut (les tiles affichent souvent une address technique).

**État `isActive`** — `bg/raised` + `border.activeMarker` (border-left 3dp `accent/primary`).

### 4.4 AppCard

Container avec slots header / body / footer optionnels.

```dart
AppCard(
  headerTitle: 'Authentication',        // null = pas de header
  headerTrailing: Text('key'),          // optionnel
  child: Column(...),
  footer: Row(actions),                 // null = pas de footer
);
```

**Header** — `type/heading` uppercase tracking, padding `space/md` `space/lg`, separator `border.hair`.
**Body** — padding `space/lg`.
**Footer** — bg `bg/canvas` (un cran plus sombre que le body en `bg/surface`, effet "tray underneath"), separator `border.hair` top, padding `space/md` `space/lg`, actions alignées à droite avec gap `space/sm`.
**Background** — `bg/surface`. Border `border.standard`. Radius `radius/lg` (12).

### 4.5 AppSheet

Template pour bottom sheets. Unifie les 5 sheets existants (password / KI / host mismatch / confirm / key editor) + variable dialog.

```dart
showAppSheet(
  context: context,
  builder: (ctx) => AppSheet(
    title: 'Host key changed',
    subtitle: 'prod.example.com:22 — fingerprint different from last connection',
    child: HostKeyDiffWidget(...),
    actions: [
      AppButton(label: 'Cancel', variant: .ghost, onPressed: () => Navigator.pop(ctx)),
      AppButton(label: 'Accept once', variant: .secondary, onPressed: ...),
      AppButton(label: 'Reject', variant: .danger, onPressed: ...),
    ],
  ),
);
```

**Layout :**
1. Grab indicator (36×4dp, fill `border/default`, margin `space/sm` auto).
2. Header — `padding space/sm space/xl space/md`. Title `type/title`, subtitle `type/caption` color `content/muted`.
3. Body — `padding 0 space/xl space/lg`.
4. Actions — `padding space/md space/xl space/xl`, separator `border.hair` top, row right-aligned, gap `space/sm`.

**Background** `bg/surface`, `border.hair` top, `radius/sheet` (16 top only).

**Animation enter** : 300ms emphasized (cf. motion patterns).

## 5. Architecture & implémentation

### 5.1 Organisation fichiers

```
lib/presentation/design/
├── tokens/
│   ├── app_colors.dart          // Surface, content, accent, state, focusGlow
│   ├── app_typography.dart      // TextStyles pour chaque token typo
│   ├── app_spacing.dart         // const dp values
│   ├── app_radius.dart          // BorderRadius helpers
│   ├── app_borders.dart         // BorderSide helpers
│   └── app_motion.dart          // Duration + Curve constants
├── theme/
│   └── app_theme.dart           // ThemeData factory consommant les tokens
└── widgets/
    ├── app_button.dart
    ├── app_text_field.dart
    ├── app_tile.dart
    ├── app_card.dart
    └── app_sheet.dart
```

### 5.2 Compatibilité Material

`app_theme.dart` produit un `ThemeData` qui mappe :
- `colorScheme.primary` ← `accent/primary`
- `colorScheme.surface` ← `bg/surface`
- `colorScheme.onSurface` ← `content/primary`
- `colorScheme.error` ← `state/error`
- `textTheme` ← échelle typo (mappage Material 3 : `displaySmall`, `titleLarge`, etc.)
- `inputDecorationTheme` cohérent avec `AppTextField`.

Comme ça les widgets Material existants (avant le refactor screen-par-screen) restent dans le ton tant qu'ils ne sont pas migrés vers les primitives.

### 5.3 Famille mono — JetBrains Mono

- Ajouter `assets/fonts/JetBrainsMono-Regular.ttf` + `Bold.ttf` (suffit pour notre échelle).
- Déclarer dans `pubspec.yaml` sous `flutter > fonts`.
- `app_typography.dart` expose `mono*` styles pointant vers `'JetBrainsMono'`.

### 5.4 Tests

Pour chaque primitive, un fichier `test/presentation/design/widgets/<primitive>_test.dart` qui couvre :
- Chaque variante / configuration majeure (golden tests si on les met en place, sinon assertions sur la structure du widget).
- Les états (rest / focus / error / disabled, loading pour AppButton).
- Le câblage des callbacks (`onPressed`, `onTap`).

Pas de test golden bloquant pour cette première itération (deferred à une vraie infra de visual regression). Tests unitaires de structure suffisants.

## 6. Critères de succès

- [ ] Tous les tokens compilent et sont consommables via `AppColors`, `AppTypography`, `AppSpacing`, etc.
- [ ] Les 5 primitives existent, exposent l'API documentée, et chaque variante/état est testée.
- [ ] `app_theme.dart` produit un `ThemeData` sans warning, et les écrans existants restent fonctionnels (pas de regression visuelle bloquante avant le refactor).
- [ ] JetBrains Mono s'affiche correctement sur device.
- [ ] `flutter analyze --fatal-infos` reste vert.
- [ ] `flutter test` reste vert.
- [ ] Une page de démo `lib/presentation/design/_gallery_screen.dart` (debug-only, accessible via Settings → Debug en build debug) montre toutes les primitives et leurs états — pour valider visuellement à l'œil sur device avant de commencer le refactor screen-par-screen.

## 7. Out of scope (rappel)

- Refactor des écrans existants pour consommer les primitives → sous-projets ultérieurs (un par écran, à prioriser après cette foundation).
- États empty / loading / error sur les écrans existants → sous-projet UX layer.
- Animations spécifiques par écran → sous-projet motion layer.
- Onboarding, flows d'arrivée, navigation IA → sous-projet flows.

Les sous-projets suivants seront brainstormés un par un. Cette foundation pose juste le terrain.

---

## Annexes

- Mockups visuels du brainstorm : `.superpowers/brainstorm/34763-1777368678/content/` (palette, typography, spacing-radius, motion, primitives-v3). Non commités (gitignored).
- Direction aesthetic comparée à 3 alternatives ; "Matrix Refined" choisie pour ne pas changer l'identité en l'absence du dev principal.
