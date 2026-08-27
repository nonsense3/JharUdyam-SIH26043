import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { supabase } from '../lib/supabase'
import { getProfile } from '../lib/api'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null)
  const [profile, setProfile] = useState(null)
  const [status, setStatus] = useState('loading') // loading | ready
  const [profileError, setProfileError] = useState(null)

  useEffect(() => {
    // Local to this effect run so React 18 StrictMode's mount/unmount/mount
    // cycle can't have the first run's cleanup disable the second run.
    let active = true

    supabase.auth
      .getSession()
      .then(({ data }) => {
        if (!active) return
        setSession(data.session ?? null)
        if (!data.session) setStatus('ready')
      })
      .catch(() => active && setStatus('ready'))

    // Note: no awaiting Supabase calls inside this callback — the client can
    // deadlock if you query the database from inside an auth event.
    const { data: sub } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      if (!active) return
      setSession(nextSession ?? null)
      if (!nextSession) {
        setProfile(null)
        setProfileError(null)
        setStatus('ready')
      }
    })

    return () => {
      active = false
      sub.subscription.unsubscribe()
    }
  }, [])

  // Load the profile (which holds the role) whenever the signed-in user changes.
  const userId = session?.user?.id ?? null
  useEffect(() => {
    if (!userId) return
    let cancelled = false
    setStatus('loading')
    setProfileError(null)

    getProfile(userId)
      .then((row) => {
        if (cancelled) return
        setProfile(row ?? null)
        setStatus('ready')
      })
      .catch((err) => {
        if (cancelled) return
        setProfileError(err.message ?? 'Could not load your profile.')
        setProfile(null)
        setStatus('ready')
      })

    return () => {
      cancelled = true
    }
  }, [userId])

  const value = useMemo(
    () => ({
      session,
      user: session?.user ?? null,
      profile,
      role: profile?.role ?? null,
      loading: status === 'loading',
      profileError,

      signIn: async (email, password) => {
        const { error } = await supabase.auth.signInWithPassword({
          email: email.trim(),
          password,
        })
        if (error) throw error
      },

      /**
       * Creates a portal account and — because "Confirm email" is switched off in
       * the Supabase project — signs it straight in.
       *
       * Everything under `options.data` is stored on auth.users.raw_user_meta_data,
       * which is exactly what the handle_new_user() database trigger reads to build
       * the matching public.profiles row: full name, role, department and
       * organisation. That is why nothing is inserted into `profiles` from here.
       * One call creates both rows inside a single transaction, so the profile can
       * never be missing by the time we go looking for it.
       *
       * Returns the session when the account is usable immediately, or null when
       * the project still insists on a confirmation email.
       */
      signUp: async ({ email, password, fullName, role, department, organization }) => {
        const { data, error } = await supabase.auth.signUp({
          email: email.trim(),
          password,
          options: {
            data: {
              full_name: fullName.trim(),
              role,
              // The field that does not apply to this role goes in as null rather
              // than an empty string, so the column reads as "not set" instead of
              // holding a blank value that looks deliberate.
              department: department?.trim() || null,
              organization: organization?.trim() || null,
            },
          },
        })
        if (error) throw error

        // A duplicate address is reported as an error while email confirmation is
        // off. With it on, Supabase instead returns a user carrying no identities
        // — deliberately vague, so it cannot be used to discover which addresses
        // are registered. Translate that into something the form can act on.
        if (data.user?.identities?.length === 0) {
          throw new Error('An account already exists for this email. Sign in instead.')
        }

        return data.session ?? null
      },

      signOut: async () => {
        await supabase.auth.signOut()
        setProfile(null)
        setSession(null)
      },

      refreshProfile: async () => {
        if (!userId) return
        const row = await getProfile(userId)
        setProfile(row ?? null)
        return row
      },
    }),
    [session, profile, status, profileError, userId]
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>')
  return ctx
}
