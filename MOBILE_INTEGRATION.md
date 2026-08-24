# Mobile app ↔ web portal contract

For whoever is building the citizen mobile app. Both apps talk to the **same**
Supabase project, so this is the only thing the two of us need to agree on.

The mobile app needs the same two values the web portal uses:

```
Project URL   https://zkphbmcvaiofabwzmiqa.supabase.co
anon key      eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InprcGhibWN2YWlvZmFid3ptaXFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1ODQwOTgsImV4cCI6MjEwMzE2MDA5OH0.qsPSTy3i-xNW_Yojzzs9GkVOfwYcJ3YmczRYRlpM_5Y
```

Use the URL exactly as written, with no `/rest/v1/` on the end — the Supabase
client library appends that itself.

The `anon` key is designed to be shipped inside client apps: it only ever gets
the access the row level security rules allow. The key you must **never** put in
the mobile app is the `service_role` / `sb_secret_…` one, which bypasses every
rule.

If Supabase's dashboard shows you a newer `sb_publishable_…` key instead, the
`anon` key above still works and is the safer choice here, because it is the
format this project's pinned client library was built against.

---

## What the mobile app owns

1. Signing citizens up and in.
2. Uploading the photograph.
3. Calling the AI and writing the structured result.

## What the web portal owns

Everything after that: review, the release decision, interest, and status
changes. The mobile app should never need to write to `status`, `released_to`,
or the `interests` table.

---

## 1 · Citizen sign-up

Create the account with `role: 'citizen'` in the metadata. A database trigger
turns that into a `profiles` row automatically — do not insert into `profiles`
by hand.

```js
await supabase.auth.signUp({
  email,
  password,
  options: {
    data: { full_name: 'Citizen name', role: 'citizen' },
  },
})
```

If `role` is left out it defaults to `citizen` anyway, so this is belt and
braces.

A citizen can read the reports they submitted and nothing else. They cannot see
other citizens' reports, and they cannot see the portal.

---

## 2 · Upload the photograph

The bucket `problem-images` already exists and is public-read.

```js
const path = `${userId}/${Date.now()}.jpg`

await supabase.storage
  .from('problem-images')
  .upload(path, fileOrBlob, { contentType: 'image/jpeg' })

const { data } = supabase.storage.from('problem-images').getPublicUrl(path)
const imageUrl = data.publicUrl
```

Keep both values: `path` goes in `image_path`, `imageUrl` goes in `image_url`.
The web portal displays `image_url`.

---

## 3 · Insert the problem

One insert, after the AI has run.

```js
const { data, error } = await supabase.from('problems').insert({
  // ---- from the AI ----
  title:        'Deep pothole on Ranchi–Khunti road near Namkum crossing',
  description:  'A pothole roughly one metre across…',   // 2–4 sentences
  category:     'Road Infrastructure',
  priority:     'high',            // low | medium | high | critical
  department:   'Public Works',    // must match a government user's department
  duplicate_of: null,              // or the id of the earlier report

  // ---- from the phone ----
  image_url:    imageUrl,
  image_path:   path,
  latitude:     23.3652,
  longitude:    85.3846,
  address:      'Namkum Crossing, Ranchi–Khunti Road, Ranchi',

  // ---- who reported it ----
  reporter_id:   userId,           // must equal the signed-in user's id
  reporter_name: 'Citizen name',
}).select().single()
```

**Do not set** `status`, `released_to`, `ticket_no`, `created_at` or
`updated_at`. The database fills those in — `status` starts at `submitted`,
`released_to` at `none`, and `ticket_no` is generated as `JU-26-0001`,
`JU-26-0002`, and so on.

`reporter_id` **must** be the signed-in user's own id, or the insert is
rejected by the security rules.

The moment this insert lands, the report appears on the dashboard of every
government user in that `department`, and they each get a notification. Nothing
else is needed from the mobile side.

---

## Field reference

| Column | Type | Who writes it | Notes |
|---|---|---|---|
| `title` | text | mobile (AI) | One line. Shown as the heading everywhere. |
| `description` | text | mobile (AI) | 2–4 sentences of plain description. |
| `category` | text | mobile (AI) | Free text, e.g. `Road Infrastructure`. |
| `priority` | enum | mobile (AI) | `low` `medium` `high` `critical` |
| `department` | text | mobile (AI) | Must match a government profile's `department`. |
| `duplicate_of` | uuid | mobile (AI) | Id of the earlier report, or `null`. |
| `image_url` | text | mobile | Public URL. Shown in all three portals. |
| `image_path` | text | mobile | Storage path, kept for reference. |
| `latitude` / `longitude` | float8 | mobile | Decimal degrees. |
| `address` | text | mobile | Reverse-geocoded, or whatever the citizen typed. |
| `reporter_id` | uuid | mobile | Must be `auth.uid()`. |
| `reporter_name` | text | mobile | Display name. |
| `status` | enum | **portal** | Starts at `submitted`. |
| `released_to` | enum | **portal** | Starts at `none`. |
| `government_note` | text | **portal** | Note the department writes for partners. |
| `ticket_no` | text | database | Auto-generated. |

---

## The department list

`department` is free text, but it has to match a government account exactly or
nobody will see the report. Agree on this list and have the AI pick from it:

```
Public Works
Water Supply & Sanitation
Electricity
Municipal Solid Waste
Health
Transport
Urban Development
Environment & Forests
```

Only `Public Works` has a government login in the demo seed. To add more, see
the last section of `SUPABASE_SETUP.md`.

If the AI cannot work out the department, `Public Works` is the safest fallback
for the demo — better than `null`, which only a state-level account would see.

---

## Reading a citizen's own reports

For a "my reports" screen in the mobile app:

```js
const { data } = await supabase
  .from('problems')
  .select('id, ticket_no, title, category, priority, status, image_url, created_at')
  .order('created_at', { ascending: false })
```

No `.eq('reporter_id', …)` is needed — the security rules already restrict a
citizen to their own rows. Adding it does no harm.

The `status` values a citizen may see, and reasonable wording for them:

| Value | Say something like |
|---|---|
| `submitted` | Sent to the department |
| `under_review` | Being reviewed |
| `government_handling` | The department is handling it |
| `released` | Opened up for outside help |
| `interest_expressed` | An organisation has offered to help |
| `in_progress` | Work has started |
| `resolved` | Resolved |

---

## What the mobile app must not do

- Do not insert into `profiles` — the trigger handles it.
- Do not write `status` or `released_to`. Those belong to the government, and
  the security rules will reject the attempt.
- Do not write to `interests` — that is universities and industries only.
- Do not use the `service_role` key in the mobile app. Anon key only.

---

## Testing the join between the two apps

1. Submit a report from the mobile app.
2. Sign into the web portal as `gov@jharudyam.test`.
3. It should be at the top of the department queue within a second or two, with
   the photograph, the map coordinates and the AI's category and priority.

If it does not appear, check the `department` value on the row against the
government profile's `department`:

```sql
select ticket_no, department, status from public.problems order by created_at desc limit 5;
select full_name, department from public.profiles where role = 'government';
```

Nine times out of ten it is a spelling mismatch there.
