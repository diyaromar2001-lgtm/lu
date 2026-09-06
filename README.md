# PreTalli Coiffure — Site vitrine avec réservation en ligne

Site vitrine autonome pour PreTalli Coiffure (Courroux, Jura) avec un
**système de réservation intégré** (sans dépendance à Salonkee).

## Fonctionnalités

- Page d'accueil élégante (À propos, Prestations, Avis, Horaires, Contact)
- Réservation en 4 étapes :
  1. Choix de la prestation
  2. Choix de la date (calendrier, jours fermés/dépassés désactivés)
  3. Choix de l'heure (créneaux de 30 min selon les horaires d'ouverture)
  4. Coordonnées + confirmation
- Les créneaux déjà réservés sont **bloqués pour tous les visiteurs** (via Supabase)
- Confirmation envoyée à la coiffeuse par **WhatsApp**
- La coiffeuse consulte/gère les réservations dans le dashboard Supabase

## Prérequis

- Compte gratuit sur [Supabase](https://supabase.com)

## Installation

### 1. Créer le projet Supabase

1. Allez sur https://supabase.com → "New project"
2. Choisissez un nom (ex : `pretalli-coiffure`), un mot de passe de base de données, une région proche (Europe)
3. Attendez la fin de la création (~1 min)

### 2. Créer la table

1. Menu **SQL Editor** → **New query**
2. Copiez le contenu du fichier [`database.sql`](database.sql)
3. Cliquez sur **Run**

### 3. Récupérer les clés API

1. Menu **Project Settings** → **API**
2. Notez :
   - **Project URL** (`https://xxxx.supabase.co`)
   - **anon public key** (la clé `anon`, PAS la `service_role`)

### 4. Configurer le site

Ouvrez [`config.js`](config.js) et remplacez :

```js
const SUPABASE_URL = 'https://VOTRE-PROJET.supabase.co';   // ← Project URL
const SUPABASE_ANON_KEY = 'COLLEZ-VOTRE-CLE-ANON-ICI';      // ← anon public key
```

### 5. Mettre en ligne

Hébergez les **4 fichiers** suivants sur n'importe quel hébergeur
(GitHub Pages, Netlify, Vercel, hosting classique...):

```
pretalli-site/
├── index.html
├── config.js
├── database.sql   (optionnel, pour référence)
└── README.md      (optionnel, pour référence)
```

## Gérer les réservations (côté coiffeuse)

Dans l'interface Supabase :

- **Table Editor** → table `bookings` : voir toutes les demandes
  (nom, téléphone, prestation, date, heure, statut)
- Pour **annuler** une demande (créneau reperdu pour les clients) :
  passez `status` de `pending` à `cancelled`

Le site ignore automatiquement les lignes avec `status = 'cancelled'`.

## Développement en local

Pour tester en local, servez le dossier (l'API Supabase exige un vrai domaine,
pas un `file://`) :

```bash
# Avec Python
python -m http.server 8080

# Ou avec Node
npx serve .
```

Puis ouvrez http://localhost:8080

## Structure

| Fichier          | Rôle                                              |
|------------------|---------------------------------------------------|
| `index.html`     | Site complet (design + logique de réservation)    |
| `config.js`      | Vos clés Supabase + numéro WhatsApp               |
| `database.sql`   | Script SQL à exécuter dans Supabase (une fois)    |

## Personnalisation rapide

- **WhatsApp** : modifiez `WA_NUMBER` dans `config.js` (format international sans `+`)
- **Horaires d'ouverture** : modifiez `OPEN_HOURS` dans `index.html` (objet JS)
- **Prestations / prix** : modifiez l'objet `SERVICES` dans `index.html`