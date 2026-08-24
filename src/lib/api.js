// ---------------------------------------------------------------------------
// Every database call the portal makes lives here, so the screens stay simple.
//
// Note on security: these queries do not filter by role. They don't need to —
// the row level security rules in supabase/schema.sql already limit each user
// to the rows they are allowed to see. The extra filters below are for clarity
// and ordering only.
// ---------------------------------------------------------------------------

import { supabase } from './supabase'

const PROBLEM_FIELDS = `
  id, ticket_no, title, description, category, priority, department, status,
  image_url, address, latitude, longitude, reporter_name,
  released_to, released_at, government_note, duplicate_of,
  created_at, updated_at
`

/* ------------------------------------------------------------------ problems */

/** Problems for the signed-in government user's department. */
export async function listDepartmentProblems() {
  const { data, error } = await supabase
    .from('problems')
    .select(PROBLEM_FIELDS)
    .order('created_at', { ascending: false })
  if (error) throw error
  return data ?? []
}

/** Problems the government has released to this kind of organisation. */
export async function listReleasedProblems(orgType) {
  const scopes = orgType === 'university' ? ['university', 'both'] : ['industry', 'both']
  const { data, error } = await supabase
    .from('problems')
    .select(PROBLEM_FIELDS)
    .in('released_to', scopes)
    .order('released_at', { ascending: false, nullsFirst: false })
  if (error) throw error
  return data ?? []
}

export async function getProblem(id) {
  const { data, error } = await supabase
    .from('problems')
    .select(PROBLEM_FIELDS)
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  return data
}

/**
 * Marks a freshly submitted problem as opened by the department.
 * Silently does nothing if the problem has already moved on.
 */
export async function markUnderReview(id) {
  const { error } = await supabase
    .from('problems')
    .update({ status: 'under_review' })
    .eq('id', id)
    .eq('status', 'submitted')
  if (error) throw error
}

/**
 * The government decision. `decision` is one of:
 *   'internal' | 'university' | 'industry' | 'both'
 */
export async function decideProblem(id, decision, note, userId) {
  const patch =
    decision === 'internal'
      ? {
          status: 'government_handling',
          released_to: 'none',
          released_at: null,
          released_by: null,
        }
      : {
          status: 'released',
          released_to: decision,
          released_at: new Date().toISOString(),
          released_by: userId ?? null,
        }

  if (note !== undefined) patch.government_note = note || null

  const { data, error } = await supabase
    .from('problems')
    .update(patch)
    .eq('id', id)
    .select(PROBLEM_FIELDS)
    .maybeSingle()
  if (error) throw error
  return data
}

/** Used for the two later lifecycle steps: 'in_progress' and 'resolved'. */
export async function setProblemStatus(id, status) {
  const { data, error } = await supabase
    .from('problems')
    .update({ status })
    .eq('id', id)
    .select(PROBLEM_FIELDS)
    .maybeSingle()
  if (error) throw error
  return data
}

/* ----------------------------------------------------------------- interests */

/** Interests on one problem — visible to the owning department. */
export async function listInterestsForProblem(problemId) {
  const { data, error } = await supabase
    .from('interests')
    .select('id, problem_id, org_id, org_type, org_name, status, note, created_at')
    .eq('problem_id', problemId)
    .order('created_at', { ascending: true })
  if (error) throw error
  return data ?? []
}

/** Interests belonging to the signed-in organisation, with the problem attached. */
export async function listMyInterests() {
  const { data, error } = await supabase
    .from('interests')
    .select(
      `id, problem_id, org_type, org_name, status, note, created_at,
       problem:problems ( ${PROBLEM_FIELDS} )`
    )
    .order('created_at', { ascending: false })
  if (error) throw error
  return data ?? []
}

/** Just the problem ids this organisation has already registered interest in. */
export async function listMyInterestIds() {
  const { data, error } = await supabase.from('interests').select('problem_id, status')
  if (error) throw error
  return data ?? []
}

export async function expressInterest({ problemId, profile, note }) {
  const { data, error } = await supabase
    .from('interests')
    .insert({
      problem_id: problemId,
      org_id: profile.id,
      org_type: profile.role,
      org_name: profile.organization || profile.full_name || 'Unnamed organisation',
      note: note || null,
      status: 'expressed',
    })
    .select('id, problem_id, org_type, org_name, status, note, created_at')
    .maybeSingle()
  if (error) throw error
  return data
}

export async function withdrawInterest(interestId) {
  const { error } = await supabase.from('interests').delete().eq('id', interestId)
  if (error) throw error
}

/* ------------------------------------------------------------- notifications */

export async function listNotifications(limit = 50) {
  const { data, error } = await supabase
    .from('notifications')
    .select('id, problem_id, title, body, is_read, created_at')
    .order('created_at', { ascending: false })
    .limit(limit)
  if (error) throw error
  return data ?? []
}

export async function markNotificationRead(id) {
  const { error } = await supabase.from('notifications').update({ is_read: true }).eq('id', id)
  if (error) throw error
}

export async function markAllNotificationsRead() {
  const { error } = await supabase
    .from('notifications')
    .update({ is_read: true })
    .eq('is_read', false)
  if (error) throw error
}

/* ------------------------------------------------------------------ profiles */

export async function getProfile(userId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, full_name, role, department, organization, phone, created_at')
    .eq('id', userId)
    .maybeSingle()
  if (error) throw error
  return data
}

export async function updateProfile(userId, patch) {
  const { data, error } = await supabase
    .from('profiles')
    .update(patch)
    .eq('id', userId)
    .select('id, full_name, role, department, organization, phone, created_at')
    .maybeSingle()
  if (error) throw error
  return data
}
