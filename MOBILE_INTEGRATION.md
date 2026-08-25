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

---

## Zero Login Architecture for Citizens

Citizens do **not** need to create an account, log in, or provide credentials.
When a citizen opens the mobile app, they immediately enter the app:
- They can browse all civic issues reported across Jharkhand.
- They can view their own previously submitted issues (using a local device ID or saved list).
- They can capture a photo, let AI analyze it, and submit a new report directly.

---

## What the mobile app owns

1. Browsing reported problems feed directly using the `anon` key.
2. Uploading citizen evidence photographs to the `problem-images` storage bucket.
3. Calling the AI and inserting the structured report into the `problems` table.

## What the web portal owns

Everything after that: review, the release decision, university/industry interest,
and status progression. The mobile app should never need to write to `status`,
`released_to`, or the `interests` table.

---

## 1 · Browsing problems (feed & exploration)

The mobile app can query all problems directly without signing in:

```js
const { data, error } = await supabase
  .from('problems')
  .select('id, ticket_no, title, description, category, priority, department, status, image_url, address, latitude, longitude, created_at')
  .order('created_at', { ascending: false })
```

---

## 2 · Uploading the photograph

The bucket `problem-images` is public-read and allows anonymous public uploads.

```js
const filename = `${Date.now()}-${Math.random().toString(36).substring(7)}.jpg`
const path = `citizen-uploads/${filename}`

const { error: uploadError } = await supabase.storage
  .from('problem-images')
  .upload(path, fileOrBlob, { contentType: 'image/jpeg' })

const { data } = supabase.storage.from('problem-images').getPublicUrl(path)
const imageUrl = data.publicUrl
```

Keep both values: `path` goes in `image_path`, `imageUrl` goes in `image_url`.
The web portal displays `image_url`.

---

## 3 · Submitting a new problem report

One insert, after the AI has processed the photo and location.

```js
// Optional: generate a unique device ID once and store it in AsyncStorage / SharedPreferences
// so the user can easily filter "My Reports" on their device:
const deviceId = getOrGenerateDeviceId() // e.g. "device_abc123"

const { data, error } = await supabase.from('problems').insert({
  // ---- from the AI ----
  title:        'Deep pothole on Ranchi–Khunti road near Namkum crossing',
  description:  'A pothole roughly one metre across…',   // 2–4 sentences
  category:     'Road Infrastructure',
  priority:     'high',            // low | medium | high | critical
  department:   'Public Works',    // must match a government department
  duplicate_of: null,              // or the id of an earlier matching report

  // ---- from the phone ----
  image_url:    imageUrl,
  image_path:   path,
  latitude:     23.3652,
  longitude:    85.3846,
  address:      'Namkum Crossing, Ranchi–Khunti Road, Ranchi',

  // ---- reporter info (anonymous citizen) ----
  reporter_id:   deviceId,         // optional: local device identifier
  reporter_name: 'Citizen report',
}).select().single()
```

**Do not set** `status`, `released_to`, `ticket_no`, `created_at` or
`updated_at`. The database fills those in — `status` starts at `submitted`,
`released_to` at `none`, and `ticket_no` is generated as `JU-26-0001`,
`JU-26-0002`, and so on.

The moment this insert lands, the report appears on the dashboard of every
government user in that `department`, and they each get a notification. Nothing
else is needed from the mobile side.

---

## 4 · Reading a citizen's own reports ("My Reports")

To show issues reported by the current device, simply query filtering by your
local `deviceId` or save the returned `id` in local device storage:

```js
const { data, error } = await supabase
  .from('problems')
  .select('id, ticket_no, title, category, priority, status, image_url, created_at')
  .eq('reporter_id', deviceId)
  .order('created_at', { ascending: false })
```

The `status` values a citizen may see, and reasonable wording for them:

| Value | Meaning / User Display |
|---|---|
| `submitted` | Sent to the department |
| `under_review` | Being reviewed |
| `government_handling` | The department is handling it |
| `released` | Opened up for outside help |
| `interest_expressed` | An organisation has offered to help |
| `in_progress` | Work has started |
| `resolved` | Resolved |

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
| `reporter_id` | text | mobile | Optional device ID or client tracking string. |
| `reporter_name` | text | mobile | Display name (default: "Citizen report"). |
| `status` | enum | **portal** | Starts at `submitted`. |
| `released_to` | enum | **portal** | Starts at `none`. |
| `government_note` | text | **portal** | Note the department writes for partners. |
| `ticket_no` | text | database | Auto-generated (`JU-YY-XXXX`). |

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

Only `Public Works` has a government login in the demo seed.

---

## What the mobile app must not do

- Do not attempt to sign in or create auth users for citizens.
- Do not write `status` or `released_to`. Those belong to the government.
- Do not write to `interests` — that is universities and industries only.
- Do not use the `service_role` key in the mobile app. Anon key only.
