import { useState } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { Spinner, ErrorNote } from '../components/ui'
import { DEPARTMENTS, roleMeta } from '../lib/constants'
import { IconLandmark, IconCap, IconFactory, IconCheck } from '../components/Icons'
import logoImg from '../assets/logo.jpeg'

/**
 * What each role has to tell us beyond name, email and password.
 *
 * A government account is scoped to a single department, and the report it needs
 * to see has that department written on it by the mobile app's AI — so the two
 * strings have to match character for character. That is why this one is a fixed
 * dropdown while the others are free text: a university can call itself whatever
 * it likes, but a mistyped department silently hides every report.
 */
const ROLE_FIELDS = {
  government: {
    label: 'Government',
    icon: IconLandmark,
    // Selected state borrows the role's own colour, the same way status and
    // priority chips do, so the picker agrees with the rest of the interface.
    selectedClass: 'border-gov/40 bg-gov/10 text-gov',
    iconClass: 'text-gov',
    blurb: 'Receive citizen reports for your department and decide what happens to them.',
    field: 'department',
    fieldLabel: 'Department',
    fieldHint: 'You will only see citizen reports routed to this department.',
  },
  university: {
    label: 'University',
    icon: IconCap,
    selectedClass: 'border-univ/40 bg-univ/10 text-univ',
    iconClass: 'text-univ',
    blurb: 'Browse problems the government has opened up, and offer to work on them.',
    field: 'organization',
    fieldLabel: 'University name',
    fieldPlaceholder: 'e.g. BIT Mesra',
    fieldHint: 'Shown to the department when you express interest in a challenge.',
  },
  industry: {
    label: 'Industry',
    icon: IconFactory,
    selectedClass: 'border-ind/40 bg-ind/10 text-ind',
    iconClass: 'text-ind',
    blurb: 'Browse released challenges and put your capability behind the ones that fit.',
    field: 'organization',
    fieldLabel: 'Company or organisation',
    fieldPlaceholder: 'e.g. Tata Steel Foundation',
    fieldHint: 'Shown to the department when you express interest in a challenge.',
  },
}

const ROLE_KEYS = ['government', 'university', 'industry']

const MIN_PASSWORD = 8

export default function Register() {
  const { session, role: userRole, loading, signUp } = useAuth()

  const [role, setRole] = useState('government')
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [department, setDepartment] = useState('')
  const [organization, setOrganization] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')

  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)
  const [needsEmailConfirm, setNeedsEmailConfirm] = useState(false)

  const spec = ROLE_FIELDS[role]

  // The account was created and the session has already arrived, so hand over to
  // "/" and let it work out which dashboard this role belongs on. While the
  // profile is still loading, hold a quiet splash rather than letting the filled
  // in form flash back into view on the way out.
  if (session) {
    if (loading) {
      return (
        <div className="flex min-h-screen items-center justify-center gap-2.5 text-sm text-mute">
          <Spinner />
          Setting up your account
        </div>
      )
    }
    const home = roleMeta(userRole)?.home ?? '/government'
    return <Navigate to={home} replace />
  }

  function validate() {
    if (!fullName.trim()) return 'Please enter your name.'
    if (spec.field === 'department' && !department) return 'Please choose your department.'
    if (spec.field === 'organization' && !organization.trim()) {
      return `Please enter your ${spec.fieldLabel.toLowerCase()}.`
    }
    if (password.length < MIN_PASSWORD) {
      return `Use at least ${MIN_PASSWORD} characters for your password.`
    }
    if (password !== confirm) return 'The two passwords do not match.'
    return null
  }

  async function onSubmit(e) {
    e.preventDefault()
    const problem = validate()
    if (problem) {
      setError(problem)
      return
    }

    setError(null)
    setBusy(true)
    try {
      const newSession = await signUp({
        email,
        password,
        fullName,
        role,
        // Only one of these is ever meaningful; signUp turns the other into null.
        department: spec.field === 'department' ? department : '',
        organization: spec.field === 'organization' ? organization : '',
      })

      // No session means the project is still asking for a confirmation email.
      // Nothing is broken — the account exists, it just cannot sign in yet.
      if (!newSession) setNeedsEmailConfirm(true)
    } catch (err) {
      const message = err?.message ?? 'The account could not be created.'
      setError(
        /already registered|already exists/i.test(message)
          ? 'An account already exists for this email. Sign in instead.'
          : message
      )
    } finally {
      setBusy(false)
    }
  }

  if (needsEmailConfirm) {
    return (
      <div className="flex min-h-screen items-center justify-center px-5 py-12">
        <div className="w-full max-w-sm text-center">
          <span className="mx-auto flex h-11 w-11 items-center justify-center rounded-full border border-brand/30 bg-brand-tint text-brand-dark">
            <IconCheck width={18} height={18} />
          </span>
          <h1 className="mt-4 font-display text-lg font-semibold tracking-tight text-ink">
            Account created
          </h1>
          <p className="mt-2 text-sm text-ash">
            This Supabase project is still set to confirm email addresses, so check{' '}
            <span className="font-mono text-xs text-ink">{email.trim()}</span> for a confirmation
            link before signing in.
          </p>
          <p className="mt-3 text-xs text-mute">
            For a demo you can turn this off: Supabase → Authentication → Sign In / Providers →
            switch <span className="font-medium">Confirm email</span> off.
          </p>
          <Link to="/login" className="btn-outline mt-6 inline-flex">
            Back to sign in
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[1fr_1.05fr]">
      {/* ---------------- who this portal is for ---------------- */}
      <section className="relative flex flex-col justify-between overflow-hidden bg-ink px-7 py-10 text-white sm:px-12 lg:py-14">
        <Link to="/login" className="flex w-fit items-center gap-3">
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
        </Link>

        <div className="max-w-md py-12">
          <p className="font-mono text-2xs uppercase tracking-[0.16em] text-brand">
            Three kinds of account
          </p>
          <h1 className="mt-3 font-display text-[1.75rem] font-semibold leading-[1.15] tracking-tightest sm:text-[2.15rem]">
            Register the side of the problem you sit on.
          </h1>
          <p className="mt-4 text-sm leading-relaxed text-white/60">
            Your role decides what the database will hand you, so choose it carefully. Citizens do
            not register at all — they report from the mobile app without an account.
          </p>

          <ul className="mt-9 space-y-4">
            {ROLE_KEYS.map((key) => {
              const item = ROLE_FIELDS[key]
              return (
                <li key={key} className="flex gap-3.5">
                  <item.icon width={16} height={16} className="mt-0.5 shrink-0 text-brand" />
                  <div>
                    <p className="text-sm font-medium text-white">{item.label}</p>
                    <p className="mt-0.5 text-xs leading-relaxed text-white/45">{item.blurb}</p>
                  </div>
                </li>
              )
            })}
          </ul>
        </div>

        <p className="font-mono text-2xs text-white/30">
          Smart India Hackathon 2026 · SIH26043 · prototype
        </p>
      </section>

      {/* ---------------- the form ---------------- */}
      <section className="flex items-center justify-center px-5 py-12 sm:px-10">
        <div className="w-full max-w-sm">
          <h2 className="font-display text-xl font-semibold tracking-tight text-ink">
            Create your account
          </h2>
          <p className="mt-1.5 text-sm text-ash">
            Already registered?{' '}
            <Link to="/login" className="font-medium text-brand hover:underline">
              Sign in
            </Link>
            .
          </p>

          <form onSubmit={onSubmit} className="mt-7 space-y-4">
            {/* --- role --- */}
            <fieldset>
              <legend className="field-label">I represent</legend>
              <div className="grid grid-cols-3 gap-1.5">
                {ROLE_KEYS.map((key) => {
                  const item = ROLE_FIELDS[key]
                  const selected = role === key
                  return (
                    <button
                      key={key}
                      type="button"
                      aria-pressed={selected}
                      onClick={() => {
                        setRole(key)
                        setError(null)
                      }}
                      className={`flex flex-col items-center gap-1.5 rounded-md border px-2 py-3 text-xs font-medium transition-colors ${
                        selected
                          ? item.selectedClass
                          : 'border-line bg-surface text-ash hover:border-ash hover:bg-paper'
                      }`}
                    >
                      <item.icon
                        width={16}
                        height={16}
                        className={selected ? item.iconClass : 'text-mute'}
                      />
                      {item.label}
                    </button>
                  )
                })}
              </div>
            </fieldset>

            {/* --- name --- */}
            <div>
              <label htmlFor="fullName" className="field-label">
                Your full name
              </label>
              <input
                id="fullName"
                autoComplete="name"
                required
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                className="input"
                placeholder="e.g. R. Mahato"
              />
            </div>

            {/* --- department (government) or organisation (university / industry) --- */}
            {spec.field === 'department' ? (
              <div>
                <label htmlFor="department" className="field-label">
                  {spec.fieldLabel}
                </label>
                <select
                  id="department"
                  required
                  value={department}
                  onChange={(e) => setDepartment(e.target.value)}
                  className="input"
                >
                  <option value="">Choose a department…</option>
                  {DEPARTMENTS.map((name) => (
                    <option key={name} value={name}>
                      {name}
                    </option>
                  ))}
                </select>
                <p className="mt-1.5 text-xs text-mute">{spec.fieldHint}</p>
              </div>
            ) : (
              <div>
                <label htmlFor="organization" className="field-label">
                  {spec.fieldLabel}
                </label>
                <input
                  id="organization"
                  autoComplete="organization"
                  required
                  value={organization}
                  onChange={(e) => setOrganization(e.target.value)}
                  className="input"
                  placeholder={spec.fieldPlaceholder}
                />
                <p className="mt-1.5 text-xs text-mute">{spec.fieldHint}</p>
              </div>
            )}

            {/* --- email --- */}
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

            {/* --- password --- */}
            <div>
              <label htmlFor="password" className="field-label">
                Password
              </label>
              <input
                id="password"
                type="password"
                autoComplete="new-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="input"
                placeholder="••••••••"
              />
              <p className="mt-1.5 text-xs text-mute">At least {MIN_PASSWORD} characters.</p>
            </div>

            <div>
              <label htmlFor="confirm" className="field-label">
                Confirm password
              </label>
              <input
                id="confirm"
                type="password"
                autoComplete="new-password"
                required
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                className="input"
                placeholder="••••••••"
              />
            </div>

            <ErrorNote>{error}</ErrorNote>

            <button type="submit" disabled={busy} className="btn-primary w-full">
              {busy ? <Spinner /> : null}
              {busy ? 'Creating account' : 'Create account'}
            </button>
          </form>

          <p className="mt-5 text-xs leading-relaxed text-mute">
            Registering as {spec.label.toLowerCase()} gives this login{' '}
            {role === 'government'
              ? 'the department control desk, including the decision to release a citizen report for outside help.'
              : 'the collaboration board, which shows only the problems a department has chosen to release.'}
          </p>
        </div>
      </section>
    </div>
  )
}
