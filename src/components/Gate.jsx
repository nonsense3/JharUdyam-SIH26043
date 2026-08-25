import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { roleMeta } from '../lib/constants'
import { Spinner } from './ui'
import { IconAlert } from './Icons'

function Splash({ label }) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-paper">
      <div className="flex items-center gap-3 text-sm text-ash">
        <Spinner className="h-4 w-4" />
        {label}
      </div>
    </div>
  )
}

function Blocked({ title, children, onSignOut }) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-paper px-4">
      <div className="card max-w-md p-7 text-center">
        <span className="mx-auto mb-4 flex h-10 w-10 items-center justify-center rounded-full border border-line bg-paper text-ash">
          <IconAlert />
        </span>
        <h1 className="text-lg font-semibold text-ink">{title}</h1>
        <div className="mt-2 text-sm text-ash">{children}</div>
        <button type="button" onClick={onSignOut} className="btn-outline mt-5">
          Sign out
        </button>
      </div>
    </div>
  )
}

/**
 * Wraps every portal page. Checks three things in order: is there a session,
 * does the account have a role, and is that role allowed on this route.
 */
export function ProtectedRoute({ allow, children }) {
  const { session, profile, role, loading, profileError, signOut } = useAuth()
  const location = useLocation()

  if (loading) return <Splash label="Checking your access" />

  if (!session) return <Navigate to="/login" replace state={{ from: location.pathname }} />

  if (profileError) {
    return (
      <Blocked title="We could not load your account" onSignOut={signOut}>
        {profileError}
      </Blocked>
    )
  }

  if (!profile) {
    return (
      <Blocked title="This account has no profile yet" onSignOut={signOut}>
        Accounts created through the register page get their profile automatically. This one was
        made directly in Supabase, so it still needs a role —{' '}
        <code className="font-mono text-xs">setup_users.sql</code> assigns one.
      </Blocked>
    )
  }

  if (!allow.includes(role)) {
    // "/" resolves the right destination, and never sends anyone back here.
    const home = roleMeta(role)?.home ?? '/'
    return <Navigate to={home} replace />
  }

  return children
}

/**
 * Sends a signed-in user to the dashboard that matches their role.
 *
 * This route is the single place that decides where a signed-in user belongs, so
 * it must never bounce back to /login — the login page redirects here whenever a
 * session exists, and the two would ping-pong forever. When there is no dashboard
 * to send someone to, it says why and stops.
 */
export function RoleRedirect() {
  const { session, profile, role, loading, profileError, signOut } = useAuth()

  if (loading) return <Splash label="Opening your dashboard" />
  if (!session) return <Navigate to="/login" replace />

  const home = roleMeta(role)?.home
  if (home) return <Navigate to={home} replace />

  if (profileError) {
    return (
      <Blocked title="We could not load your account" onSignOut={signOut}>
        {profileError}
      </Blocked>
    )
  }

  if (!profile) {
    return (
      <Blocked title="This account has no profile yet" onSignOut={signOut}>
        Accounts created through the register page get their profile automatically. This one was
        made directly in Supabase, so it still needs a role —{' '}
        <code className="font-mono text-xs">setup_users.sql</code> assigns one.
      </Blocked>
    )
  }

  // Signed in with a profile, but its role is not one the portal has a dashboard
  // for. The user_role enum holds exactly the three portal roles, so this is
  // unreachable today — it exists so that adding a fourth role fails loudly here
  // instead of dropping someone onto a blank screen.
  return (
    <Blocked title="This account has no portal dashboard" onSignOut={signOut}>
      The role on this login (<code className="font-mono text-xs">{String(role)}</code>) does not
      match government, university or industry.
    </Blocked>
  )
}
