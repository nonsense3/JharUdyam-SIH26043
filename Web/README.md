# JharUdyam · web portal

The web half of our SIH26043 prototype: one application serving three
stakeholders — **Government**, **University** and **Industry** — over a shared
Supabase backend that the citizen mobile app also writes to.

The citizen mobile app is built separately by a teammate. This repository does
not contain it, and there is deliberately no way to create a problem from the
web side.

---

## The flow this implements

```
Citizen mobile app                 (teammate's app)
        │  photo + location
        ▼
AI processing                      (teammate's app — writes the structured fields)
        │  description · category · priority · department · duplicate check
        ▼
Government dashboard  ◄── this repo
        │  reviews, then decides
        ├──────────────► handle internally
        └──────────────► release to university and/or industry
                                 │
                                 ▼
                 University / Industry board  ◄── this repo
                                 │  browses, voluntarily
                                 ▼
                          Express interest
```

The government is the only gate. Nothing a citizen submits is visible to a
university or an industry until a department releases it, and that is enforced
by database security rules, not by hiding buttons in the interface.

---

## Getting it running

**First time?** Follow [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md) — it walks
through creating the Supabase project, running the SQL, and creating the three
logins, assuming no prior Supabase knowledge.

Once `.env` exists:

```bash
npm install
npm run dev
```

Open <http://localhost:5173>.

---

## What each role sees

| | Government | University | Industry |
|---|---|---|---|
| Citizen reports for its own department | ✅ | ✗ | ✗ |
| Reports from other departments | ✗ | ✗ | ✗ |
| Decide: in-house vs release | ✅ | ✗ | ✗ |
| Released problems | ✅ | only those released to universities | only those released to industry |
| Express interest | ✗ | ✅ | ✅ |
| See who expressed interest | ✅ (own department) | own interests only | own interests only |

A government account with `department = null` sees every department — useful as
a state-level account, and a handy escape hatch during a demo.

---

## Problem lifecycle

```
submitted → under_review → ┬→ government_handling → in_progress → resolved
                           └→ released → interest_expressed → in_progress → resolved
```

- `submitted` — written by the mobile app
- `under_review` — set automatically the first time a department opens the report
- everything after that — set by the government portal, except
  `interest_expressed`, which a database trigger sets when an organisation puts
  its hand up

Only these seven states exist. There is no workflow engine.

---

## Project layout

```
supabase/
  schema.sql          tables, security rules, triggers, storage bucket
  setup_users.sql     gives the three logins their roles
  seed.sql            three mock problems

src/
  lib/
    supabase.js       the client, plus a check for missing .env values
    api.js            every database call the portal makes
    constants.js      status/priority/role vocabulary and colours
  context/
    AuthContext.jsx   session + profile (which holds the role)
  components/
    Gate.jsx          route guards; sends each role to its own dashboard
    AppLayout.jsx     sidebar shell, role-aware navigation
    CustodyTrack.jsx  where a report sits in the workflow
    ProblemTable.jsx  the government queue
    ProblemCard.jsx   a released challenge, for the collaboration boards
    ui.jsx            chips, panels, empty states, error notes
  pages/
    Login.jsx
    government/       dashboard · queue · report detail and decision
    collab/           dashboard · challenge board · detail · our interests
    Notifications.jsx shared by all three roles
    Profile.jsx       shared by all three roles
```

University and industry run the *same* four screens. They are not duplicated —
the signed-in role decides which released problems the database returns.

---

## Notes for the demo

- Two browser windows, one of them private/incognito, lets you be the
  government and a university at the same time.
- The collaboration board updates itself when a release happens — no refresh
  needed. That is Supabase realtime; the *Refresh* button is there in case the
  venue wifi is unhappy.
- The empty university board *before* a release is the most important screen in
  the demo. It proves the gate exists.

Full script: [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md), Step 10.

---

## For the mobile app developer

The contract for what the mobile app must write into the database is in
[`MOBILE_INTEGRATION.md`](MOBILE_INTEGRATION.md). Nothing in the web portal
needs to change when the mobile app starts writing real reports.

---

## Deploying (optional, free)

Vercel or Netlify both host this at no cost:

1. Push this folder to a GitHub repository.
2. Import it, framework preset **Vite**, build command `npm run build`, output
   directory `dist`.
3. Add the two `VITE_SUPABASE_*` values as environment variables in the host's
   dashboard — the `.env` file is not committed.

Nothing else changes; Supabase is already remote.
