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
- **Espace admin sécurisé** (`admin.html`) :
  - Connexion par email / mot de passe (Supabase Auth)
  - Vue d'ensemble : statistiques (aujourd'hui, en attente, à venir, total)
  - Filtres (statut, période, recherche)
  - Vue **Semaine** : planning visuel des créneaux (Tableau ⇄ Semaine)
  - Détails d'un rendez-vous (client, notes, contact direct appeler / WhatsApp)
  - Modifier un rendez-vous (service, prix, date, heure, client, statut)
  - Confirmer / annuler / supprimer un rendez-vous → les créneaux se libèrent
    automatiquement pour les clients une fois annulés
- **Galerie animée** sur la page d'accueil, pilotable depuis l'admin :
  - Ajout / suppression de photos, légendes, ordre
- **Contenu du site éditable** depuis l'admin (sans toucher au code) :
  - Couleurs globales et par section, textes des titres/paragraphes,
    image de couverture (hero)
- **Horaires puisant dans une base de données** : réglables depuis l'admin,
  appliqués à la fois au calendrier de réservation et à la section "Horaires"
- **Blocage de créneaux** depuis le calendrier admin (ex. congés, indisponibilités) :
  ils sont **masqués aux clients** du site public

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

### 5. Configurer l'email administrateur (IMPORTANT)

1. Ouvrez `database.sql`
2. Remplacez `CHANGE-MOI@exemple.com` par votre email
3. Exécutez le script dans **SQL Editor** comme décrit ci-dessus
   (le script est « idempotent » : vous pouvez le re-exécuter sans risque)

### 6. Créer le compte admin

1. Allez sur `votre-site/admin.html`
2. Cliquez sur **« Créer un compte »**
3. Renseignez votre email (celui mis dans `database.sql`) + un mot de passe
4. (Si Supabase exige la confirmation email, vérifiez votre boîte mail.
   Pour désactiver : Supabase → Authentication → Providers → Email → Confirm email)

### 7. Mettre en ligne

Hébergez les **5 fichiers** suivants sur n'importe quel hébergeur
(GitHub Pages, Netlify, Vercel, hosting classique...):

```
pretalli-site/
├── index.html
├── admin.html
├── config.js
├── database.sql   (optionnel, pour référence)
└── README.md      (optionnel, pour référence)
```

## Utiliser l'espace admin

Rendez-vous sur `votre-site/admin.html` et connectez-vous :

- **Statistiques** : aujourd'hui, en attente, à venir, total
- **Filtres** : statut (attente/confirmé/terminé/annulé), période, recherche
- **👁** voir le détail complet d'un rendez-vous
- **✏️** modifier un rendez-vous
- **✓** confirmer une demande (passe de « en attente » à « confirmé »)
- **✕** annuler un rendez-vous → le créneau redevient **libre** pour les clients
- **🗑** supprimer définitivement

> Sécurité : seul l'email inscrit dans la table `admins` peut voir et gérer
> les rendez-vous. Les visiteurs du site ne voient que les créneaux occupés
> (date + heure), jamais les données clients.

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
| `index.html`     | Site public (design, galerie, réservation)      |
| `admin.html`     | Espace admin sécurisé (réservations, galerie, contenu, horaires) |
| `config.js`      | Clés Supabase + numéro WhatsApp                   |
| `database.sql`   | Script SQL à exécuter dans Supabase (une fois)    |

## Personnalisation rapide

- **WhatsApp** : modifiez `WA_NUMBER` dans `config.js` (format international sans `+`)
- **Contenu / couleurs / horaires / galerie** : connectez-vous sur `admin.html`
  → onglets **Galerie**, **Contenu**, **Horaires** (le changement est appliqué
  immédiatement sur le site public)
- **Horaires d'ouverture** : onglet **Horaires** de l'admin (ou défaut dans
  `OPEN_HOURS` dans `index.html`)
- **Prestations / prix** : modifiez l'objet `SERVICES` dans `index.html`