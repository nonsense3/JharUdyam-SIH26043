import { useState } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { Spinner, ErrorNote } from '../components/ui'
import { IconLandmark, IconCap, IconFactory } from '../components/Icons'
import logoImg from '../assets/logo.jpeg'

/** Emails created by supabase/setup_users.sql — one tap to fill the field. */
const DEMO_LOGINS = [
  { label: 'Government', email: 'gov@jharudyam.test', icon: IconLandmark, accent: 'text-gov' },
  { label: 'University', email: 'university@jharudyam.test', icon: IconCap, accent: 'text-univ' },
  { label: 'Industry', email: 'industry@jharudyam.test', icon: IconFactory, accent: 'text-ind' },
]

const CHAIN = [
  { label: 'Citizen photographs the problem', hint: 'Mobile app' },
  { label: 'AI writes it up and routes it', hint: 'Category · priority · department' },
  { label: 'Department decides what happens', hint: 'Keep in-house, or open it up' },
  { label: 'University and industry choose', hint: 'Only once it has been released' },
]

export default function Login() {
  const { session, loading, signIn } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)

  // Hand every signed-in user to "/" and let RoleRedirect decide where they
  // belong. Redirecting straight to the role's dashboard from here would loop
  // forever for an account that has no dashboard (e.g. a citizen login).
  if (session && !loading) {
    return <Navigate to="/" replace />
  }

  async function onSubmit(e) {
    e.preventDefault()
    setError(null)
    setBusy(true)
    try {
      await signIn(email, password)
    } catch (err) {
      const message = err?.message ?? 'Sign in failed.'
      setError(
        /invalid login credentials/i.test(message)
          ? 'That email and password combination does not match an account.'
          : message
      )
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[1.05fr_1fr]">
      {/* ---------------- the thesis: the chain of custody ---------------- */}
      <section className="relative flex flex-col justify-between overflow-hidden bg-ink px-7 py-10 text-white sm:px-12 lg:py-14">
        <div className="flex items-center gap-3">
          <img
            src={logoImg}
            alt="JharUdyam Logo"
            className="h-10 w-10 shrink-0 rounded-md object-contain bg-white/10 p-0.5"
          />
          <div>
            <p className="font-display text-[0.95rem] font-semibold leading-tight">JharUdyam</p>
            <p className="font-mono text-2xs uppercase tracking-[0.14em] text-white/45">
              Societal challenge platform
            </p>
          </div>
        </div>

        <div className="max-w-md py-12">
          <p className="font-mono text-2xs uppercase tracking-[0.16em] text-brand">
            Four hands, in order
          </p>
          <h1 className="mt-3 font-display text-[1.9rem] font-semibold leading-[1.15] tracking-tightest sm:text-[2.35rem]">
            A problem only reaches a research lab if the state sends it there.
          </h1>
          <p className="mt-4 text-sm leading-relaxed text-white/60">
            Citizens report what they see. The department that owns the problem decides whether to
            fix it in-house or open it to universities and industry. Nothing skips a step.
          </p>

          <ol className="mt-9 space-y-0">
            {CHAIN.map((step, i) => (
              <li key={step.label} className="flex gap-4">
                <div className="flex flex-col items-center pt-1">
                  <span className="h-2 w-2 rotate-45 border border-brand bg-brand" />
                  {i < CHAIN.length - 1 ? <span className="my-1 w-px flex-1 bg-white/15" /> : null}
                </div>
                <div className="pb-6">
                  <p className="text-sm font-medium text-white">{step.label}</p>
                  <p className="mt-0.5 font-mono text-2xs uppercase tracking-[0.1em] text-white/40">
                    {step.hint}
                  </p>
                </div>
              </li>
            ))}
          </ol>
        </div>

        <p className="font-mono text-2xs text-white/30">
          Smart India Hackathon 2026 · SIH26043 · prototype
        </p>
      </section>

      {/* ---------------- sign in ---------------- */}
      <section className="flex items-center justify-center px-5 py-12 sm:px-10">
        <div className="w-full max-w-sm">
          <h2 className="font-display text-xl font-semibold tracking-tight text-ink">
            Sign in to your portal
          </h2>
          <p className="mt-1.5 text-sm text-ash">
            Your account decides which dashboard opens — government, university or industry.
          </p>
          <p className="mt-1 text-sm text-ash">
            No account yet?{' '}
            <Link to="/register" className="font-medium text-brand hover:underline">
              Register your department or organisation
            </Link>
            .
          </p>

          <form onSubmit={onSubmit} className="mt-7 space-y-4">
            <div>
              <label htmlFor="email" className="field-label">
                Work email
              </label>
              <input
                id="email"
                type="email"
                autoComplete="username"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="input"
                placeholder="name@department.gov.in"
              />
            </div>

            <div>
              <label htmlFor="password" className="field-label">
                Password
              </label>
              <input
                id="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="input"
                placeholder="••••••••"
              />
            </div>

            <ErrorNote>{error}</ErrorNote>

            <button type="submit" disabled={busy} className="btn-primary w-full">
              {busy ? <Spinner /> : null}
              {busy ? 'Signing in' : 'Sign in'}
            </button>
          </form>

          {/* Demo convenience. Delete this block for anything real. */}
          <div className="mt-8 rounded-md border border-dashed border-line bg-surface p-4">
            <p className="eyebrow">Demo logins</p>
            <p className="mt-1.5 text-xs text-ash">
              Tap one to fill the email, then type the password you set in Supabase.
            </p>
            <div className="mt-3 grid gap-1.5">
              {DEMO_LOGINS.map((demo) => (
                <button
                  key={demo.email}
                  type="button"
                  onClick={() => setEmail(demo.email)}
                  className="flex items-center gap-2.5 rounded border border-line px-2.5 py-2 text-left text-xs transition-colors hover:border-ash hover:bg-paper"
                >
                  <demo.icon width={14} height={14} className={demo.accent} />
                  <span className="font-medium text-ink">{demo.label}</span>
                  <span className="ml-auto font-mono text-2xs text-mute">{demo.email}</span>
                </button>
              ))}
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
