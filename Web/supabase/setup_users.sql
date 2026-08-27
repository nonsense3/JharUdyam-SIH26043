-- ============================================================================
--  JharUdyam · Step 2 — give your three portal logins their roles
--
--  RUN THIS **AFTER** you have created the three users in
--  Authentication -> Users -> "Add user" (see SUPABASE_SETUP.md, Step 5).
--
--  If you used different email addresses, change them below first.
--  Running this twice is safe.
-- ============================================================================


-- ---- 1. Government representative ------------------------------------------
--  department decides which problems this person sees.
--  Set it to NULL instead if you want one account that sees every department.
update public.profiles
set role       = 'government',
    full_name  = 'R. Mahato',
    department = 'Public Works',
    organization = null
where id = (select id from auth.users where email = 'gov@jharudyam.test');


-- ---- 2. University representative ------------------------------------------
update public.profiles
set role         = 'university',
    full_name    = 'Dr. A. Sinha',
    organization = 'BIT Mesra',
    department   = null
where id = (select id from auth.users where email = 'university@jharudyam.test');


-- ---- 3. Industry representative --------------------------------------------
update public.profiles
set role         = 'industry',
    full_name    = 'S. Kujur',
    organization = 'Tata Steel Foundation',
    department   = null
where id = (select id from auth.users where email = 'industry@jharudyam.test');


-- ---- 4. Check it worked ----------------------------------------------------
--  You should see three rows, with roles government / university / industry.
select u.email,
       p.full_name,
       p.role,
       p.department,
       p.organization
from public.profiles p
join auth.users u on u.id = p.id
where u.email in (
  'gov@jharudyam.test',
  'university@jharudyam.test',
  'industry@jharudyam.test'
)
order by p.role;


-- ============================================================================
--  If a row is MISSING, that user was never created in Authentication -> Users.
--  If a row shows role 'citizen', the email above does not match exactly —
--  fix the email and run this file again.
-- ============================================================================
