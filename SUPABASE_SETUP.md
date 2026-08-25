# Supabase setup — start to finish

You have never used Supabase before, so this assumes nothing. Follow it in order.
It takes about 15 minutes. Everything here is on the free plan.

**What Supabase is, in one line:** a hosted PostgreSQL database with a login
system, file storage and a REST API bolted on, so a web app can talk to it
directly without you writing a backend server.

---

## Step 1 · Create an account

1. Go to <https://supabase.com> and click **Start your project**.
2. Sign in with GitHub (fastest) or an email address.

No card is required for the free plan.

---

## Step 2 · Create the project

1. Click **New project**.
2. Fill in:
   - **Name:** `jharudyam`
   - **Database Password:** click *Generate a password* and **save it somewhere
     you will not lose**. You will not be shown it again. (The web app does not
     need it, but you will want it later if you ever connect a database tool.)
   - **Region:** `South Asia (Mumbai)` — closest to you, so it is fastest.
3. Click **Create new project** and wait about two minutes while it starts.

---

## Step 3 · Create the tables

This is where the database structure comes from.

1. In the left sidebar click **SQL Editor**.
2. Click the **+** button and choose **Create a new snippet**. (Older versions of
   the dashboard call this **New query** — same thing: a blank SQL tab.)
3. Open `supabase/schema.sql` from this project folder, select everything
   (Ctrl+A), copy it, and paste it into the editor.
4. Click **Run** (or press Ctrl+Enter).

You should see **Success. No rows returned**. That is what success looks like
for this file.

You may also see a grey `NOTICE` about the realtime publication. That is fine
and expected — it just means that part was already done.

**To check it worked:** click **Table Editor** in the sidebar. You should now
see four tables: `profiles`, `problems`, `interests`, `notifications`.

> **What that file just did:** created the four tables, set up the problem
> lifecycle, created the security rules that stop a university from seeing an
> unreleased problem, created the image storage bucket, and set up the
> notification triggers.

---

## Step 4 · Turn off email confirmation

**Do not skip this one.** By default Supabase emails a confirmation link to every
new user, and the account cannot sign in until that link is clicked. Your email
addresses are fake `.test` ones, so that link would never arrive — and the
**Register** page in the web app would create accounts nobody can use.

1. Sidebar → **Authentication** → **Sign In / Providers** (in some versions it
   is under **Providers → Email**).
2. Find **Confirm email** and switch it **off**.
3. Click **Save**.

> The **Auto Confirm User** checkbox in Step 5 only covers users *you* create by
> hand in the dashboard. It does nothing for someone registering through the web
> app, which is why this switch matters.

---

## Step 5 · Create the three portal logins

You need one login per role. Do this three times.

1. Sidebar → **Authentication** → **Users**.
2. Click **Add user** → **Create new user**.
3. Enter:

   | Email | Password | Auto Confirm User |
   |---|---|---|
   | `gov@jharudyam.test` | pick one, e.g. `Portal@123` | ✅ tick it |
   | `university@jharudyam.test` | same password is fine | ✅ tick it |
   | `industry@jharudyam.test` | same password is fine | ✅ tick it |

4. **Tick "Auto Confirm User"** each time. Without it the login will be rejected.

Use the same password for all three — it is a demo, and it saves you fumbling
on stage.

> These are fake email addresses on purpose. `.test` is a reserved domain that
> can never be a real one, so nothing is ever sent anywhere. Supabase does not
> care that they are not deliverable.

At this point all three accounts exist, but none of them has been told *who* it
is. A user created by hand in the dashboard carries no role information, so the
database falls back to a government profile with no department — which happens to
see every department at once. Step 6 gives each one its real role.

---

## Step 6 · Give each login its role

1. Sidebar → **SQL Editor** → **+** → **Create a new snippet**.
2. Paste the whole of `supabase/setup_users.sql` and click **Run**.

This time you *will* get rows back — three of them:

| email | full_name | role | department | organization |
|---|---|---|---|---|
| gov@jharudyam.test | R. Mahato | government | Public Works | |
| industry@jharudyam.test | S. Kujur | industry | | Tata Steel Foundation |
| university@jharudyam.test | Dr. A. Sinha | university | | BIT Mesra |

**If a row is missing:** that user was not created in Step 5.
**If a role or department is wrong:** the email in the SQL does not match exactly
what you typed in Step 5. Fix the email in the file and run it again.

---

## Step 7 · Add the three mock problems

1. Sidebar → **SQL Editor** → **+** → **Create a new snippet**.
2. Paste the whole of `supabase/seed.sql` and click **Run**.

You will get three rows back — a pothole, an overflowing bin, and a dead street
light, all in `Public Works`, all `submitted`, none released. They stand in for
reports the mobile app would create.

Running this file twice will not create duplicates.

> **If a "Potential issue detected" box appears** saying the query creates a
> table without Row Level Security, choose **Run without RLS**.
>
> It is a false alarm. Supabase scans the SQL for the pattern `into <name>` to
> spot `insert into sometable`, and it can match ordinary English inside the
> report text — so it invents a table that does not exist. This file creates no
> tables at all; it only adds rows. Row Level Security was already switched on
> for all four real tables in Step 3. Picking *Run and enable RLS* would try to
> protect the imaginary table and fail.

---

## Step 8 · Copy your two keys into the web app

1. Sidebar → **Project Settings** (the gear) → **API Keys**.
2. Newer projects show two tabs here. Click the **Legacy anon, service_role API
   keys** tab and copy the key in the **`anon` `public`** row — a very long
   string starting `eyJhbGci...`.

   > **Why the legacy tab?** Supabase now also offers newer
   > `sb_publishable_...` keys and suggests preferring them. The `anon` key is
   > not deprecated and works fully — and it is the format this project's pinned
   > `@supabase/supabase-js` version was built against, so it is the safe choice
   > before a demo. If your project only shows one tab, you have the older
   > layout: just copy **anon public**.
   >
   > Do **not** click *Disable JWT-based API keys* — that switches off the very
   > key you are about to use.

3. You also need the **Project URL**. It is on **Project Settings → General**
   (or **Data API**), and it is simply `https://` + your project ref +
   `.supabase.co`. The project ref is the string in your browser's address bar
   after `/project/`.

   > If the dashboard shows the URL with `/rest/v1/` on the end, leave that part
   > off. The value in `.env` must stop at `.supabase.co` — the client library
   > adds the rest of the path itself.
4. In this project folder, make a copy of `.env.example` and name the copy
   `.env` (yes, starting with a dot, and no `.txt` on the end).
5. Open `.env` and paste your two values in:

   ```
   VITE_SUPABASE_URL=https://abcdefgh.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJhbGciOi...the-whole-long-string
   ```

6. Save the file.

> **Is the anon key safe in a browser app?** Yes. It only ever gets the access
> your security rules allow, and those rules are enforced inside the database.
> The keys you must never put here are **service_role** and **`sb_secret_...`**
> on the same page — those bypass every rule.

---

## Step 9 · Run the web app

Open a terminal in this project folder:

```bash
npm install
npm run dev
```

Then open <http://localhost:5173>.

Sign in as `gov@jharudyam.test` with the password from Step 5. You should land
on the government dashboard with three problems waiting for a decision.

---

## Step 10 · Prove the whole flow works

This is also your demo script. Use two browser windows — a normal one and a
private/incognito one — so you can be two people at once.

1. **Normal window:** sign in as `university@jharudyam.test`.
   Go to *Open challenges*. It is **empty**. This is the point of the whole
   platform: the university cannot see citizen reports.
2. **Incognito window:** sign in as `gov@jharudyam.test`.
   Open the pothole report. Choose **Release to both**, add a note like
   "Looking for a low-cost road surface assessment method", and confirm.
3. **Back to the normal window:** the challenge appears on the university board
   on its own, without a refresh.
4. Open it, write a line about how your lab would approach it, and click
   **Express interest**.
5. **Incognito window:** open that report again. BIT Mesra is now listed under
   *Interest from partners*, and the status has moved to *Interest expressed*.

That is citizen → AI → government → release → university → interest, end to end.

---

## When something goes wrong

**The app shows "Connect your Supabase project".**
`.env` is missing, misnamed, or the dev server was not restarted. Vite only
reads `.env` when it starts — stop it with Ctrl+C and run `npm run dev` again.

**"Invalid login credentials".**
Either the password is wrong, or *Auto Confirm User* was not ticked in Step 5.
Delete the user in Authentication → Users and create it again with the box
ticked.

**"This account has no profile yet".**
Step 6 has not been run, or it was run before the user existed. Run
`setup_users.sql` again.

**Registering says "Account created — check your email".**
Step 4 was skipped. Turn **Confirm email** off (Authentication → Sign In /
Providers), then confirm the waiting account by hand: Authentication → Users →
the three dots on that row → **Confirm email**. New registrations after that sign
in immediately.

**Registering says "An account already exists for this email".**
That address is already in Authentication → Users. Either sign in with it, or
delete the user there and register again.

**The government dashboard is empty.**
The government profile's `department` must match the problems' `department`.
The default for both is `Public Works`. Check with:

```sql
select role, department from public.profiles where role = 'government';
select department, count(*) from public.problems group by department;
```

If they differ, either fix the profile or re-run the seed with the matching
department. Setting the government profile's `department` to `null` makes that
account see every department, which is a useful escape hatch:

```sql
update public.profiles set department = null where role = 'government';
```

**The university board stays empty after a release.**
Check the release actually saved:

```sql
select ticket_no, status, released_to from public.problems;
```

`released_to` must be `university` or `both`. If it says `none`, the decision
did not save — look for an error in the browser console (F12).

**Images do not appear on the mock problems.**
The three seeded photos are hotlinked from the public internet, so they need a
working connection. Real reports will use your own Supabase storage bucket
instead. A missing image never breaks the layout — it shows a placeholder.

**Live updates do not happen.**
Realtime is enabled by `schema.sql`. If the board does not update on its own,
press *Refresh* — nothing else depends on realtime. To check it is on:
Sidebar → **Database** → **Publications** → `supabase_realtime` should list
`problems` and `notifications`.

---

## Adding more users later

The easiest way is the web app itself: open <http://localhost:5173/register> (or
click *Register your department or organisation* on the sign-in page). Pick a
role, fill in the form, and the account is created and signed in immediately.

**How that reaches the database.** The Register page does not write to the
`profiles` table. It passes the name, role, department and organisation to
Supabase Auth as user metadata, and a database trigger called
`handle_new_user()` reads that metadata and creates the matching `profiles` row
in the same transaction. So the role you pick on the form *is* the role stored in
Postgres, and every security rule in Step 3 applies to it from the first request.
You can watch it happen: register someone, then in **Table Editor → profiles**
the new row is already there.

Registering as government asks you to choose a department from a fixed list
rather than typing one. That is deliberate — `problems.department` has to match
`profiles.department` character for character, and a typo produces an account
that silently sees nothing.

> **Worth knowing before you demo.** Anyone who can reach the Register page can
> choose *Government* for themselves, and a signed-in user could also change
> their own role directly. Both are fine for a prototype and were a deliberate
> choice to keep the demo frictionless — the interesting security property here
> is that **the database, not the interface, decides what each role can read**.
> If a judge pushes on it, the honest answer is that production would gate
> registration behind an invite or an approval queue, and the row level security
> policies would not change at all.

### Creating a user by hand instead

If you would rather not use the form, create the user in Authentication → Users
(ticking *Auto Confirm User*), then set the role yourself:

```sql
update public.profiles
set role = 'government', full_name = 'Name here', department = 'Water Supply & Sanitation'
where id = (select id from auth.users where email = 'water@jharudyam.test');
```

That account will then see only `Water Supply & Sanitation` problems — which is a
good thing to demonstrate if a judge asks how department isolation works.

For another university or industry:

```sql
update public.profiles
set role = 'university', full_name = 'Name here', organization = 'NIT Jamshedpur'
where id = (select id from auth.users where email = 'nit@jharudyam.test');
```
