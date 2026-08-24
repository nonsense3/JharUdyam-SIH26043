-- ============================================================================
--  JharUdyam · Step 3 — three mock problems so the dashboards aren't empty
--
--  RUN THIS AFTER schema.sql and setup_users.sql.
--
--  These stand in for reports the citizen mobile app would create. They use
--  the same shape the mobile app writes, so nothing here is special-cased.
--
--  All three land in the 'Public Works' department, which is the department
--  given to the government login in setup_users.sql. If you changed that
--  department, change it here too (find/replace 'Public Works').
--
--  Running this twice will NOT create duplicates.
-- ============================================================================

insert into public.problems
  (title, description, category, priority, department,
   image_url, address, latitude, longitude,
   reporter_name, status, released_to)
select v.title, v.description, v.category, v.priority::public.priority_level, v.department,
       v.image_url, v.address, v.latitude, v.longitude,
       v.reporter_name, v.status::public.problem_status, v.released_to::public.release_scope
from (values
  (
    'Deep pothole on Ranchi–Khunti road near Namkum crossing',
    'A pothole roughly one metre across and half a metre deep has opened in the left lane just past the Namkum crossing. Two-wheelers are swerving towards traffic in the opposite lane to avoid it. Standing water in the pit hides its depth after rain.',
    'Road Infrastructure',
    'high',
    'Public Works',
    'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&w=1200&q=70',
    'Namkum Crossing, Ranchi–Khunti Road, Ranchi, Jharkhand',
    23.3652, 85.3846,
    'Citizen report · mobile app',
    'submitted',
    'none'
  ),
  (
    'Overflowing waste collection point behind Doranda market',
    'The community bin behind the vegetable market has not been cleared for several days. Waste has spread across the footpath and into the drain, and stray cattle are pulling it further into the road. Strong smell reported by nearby shopkeepers.',
    'Waste Management',
    'critical',
    'Public Works',
    'https://images.unsplash.com/photo-1611284446314-60a58ac0deb9?auto=format&fit=crop&w=1200&q=70',
    'Doranda Market, Ranchi, Jharkhand',
    23.3441, 85.3095,
    'Citizen report · mobile app',
    'submitted',
    'none'
  ),
  (
    'Street light out for three weeks on Kanke Road stretch',
    'A run of four street lights between the housing colony gate and the bus stop has been dark for about three weeks. The stretch is used by students walking back in the evening and residents have asked for it to be restored before the monsoon.',
    'Public Lighting',
    'medium',
    'Public Works',
    'https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?auto=format&fit=crop&w=1200&q=70',
    'Kanke Road, near Housing Colony, Ranchi, Jharkhand',
    23.4241, 85.3200,
    'Citizen report · mobile app',
    'submitted',
    'none'
  )
) as v (title, description, category, priority, department,
        image_url, address, latitude, longitude,
        reporter_name, status, released_to)
where not exists (
  select 1 from public.problems p where p.title = v.title
);


-- ---- Check ------------------------------------------------------------------
select ticket_no, title, department, priority, status, released_to
from public.problems
order by created_at desc;
