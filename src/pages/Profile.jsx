import { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { updateProfile } from '../lib/api'
import { roleMeta, formatDate } from '../lib/constants'
import { PageHeader, Panel, DataRow, ErrorNote, Spinner } from '../components/ui'
import { roleIcon, IconUser, IconCheck } from '../components/Icons'

export default function Profile() {
  const { user, profile, role, refreshProfile, signOut } = useAuth()
  const meta = roleMeta(role)
  const RoleIcon = roleIcon[role] ?? IconUser

  const [fullName, setFullName] = useState('')
  const [phone, setPhone] = useState('')
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState(null)

  useEffect(() => {
    setFullName(profile?.full_name ?? '')
    setPhone(profile?.phone ?? '')
  }, [profile?.full_name, profile?.phone])

  const dirty = fullName !== (profile?.full_name ?? '') || phone !== (profile?.phone ?? '')

  async function save(e) {
    e.preventDefault()
    if (!user) return
    setSaving(true)
    setError(null)
    setSaved(false)
    try {
      await updateProfile(user.id, { full_name: fullName.trim(), phone: phone.trim() || null })
      await refreshProfile()
      setSaved(true)
    } catch (err) {
      setError(err?.message ?? 'Your details could not be saved.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <PageHeader eyebrow={meta?.label} title="Profile" description="Your account and what it gives you access to." />

      <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
        <Panel title="Your details">
          <form onSubmit={save}>
            <div className="space-y-4">
              <div>
                <label htmlFor="name" className="field-label">
                  Full name
                </label>
                <input
                  id="name"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="input"
                  placeholder="How your name appears to others"
                />
              </div>
              <div>
                <label htmlFor="phone" className="field-label">
                  Contact number <span className="normal-case tracking-normal">(optional)</span>
                </label>
                <input
                  id="phone"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="input"
                  placeholder="+91"
                />
              </div>
            </div>

            <ErrorNote>{error}</ErrorNote>

            <div className="mt-4 flex items-center gap-3">
              <button type="submit" disabled={!dirty || saving} className="btn-primary">
                {saving ? <Spinner /> : null}
                {saving ? 'Saving' : 'Save changes'}
              </button>
              {saved && !dirty ? (
                <span className="flex items-center gap-1.5 text-xs text-brand-dark">
                  <IconCheck width={13} height={13} />
                  Saved
                </span>
              ) : null}
            </div>
          </form>
        </Panel>

        <div className="space-y-5">
          <Panel title="Access on this account">
            <div className="mb-4 flex items-start gap-3 rounded-md border border-line bg-paper px-4 py-3.5">
              <RoleIcon width={18} height={18} className={`mt-0.5 shrink-0 ${meta?.accent ?? ''}`} />
              <div className="min-w-0">
                <p className="text-sm font-medium text-ink">{meta?.label} representative</p>
                <p className="mt-0.5 text-xs text-ash">
                  {role === 'government'
                    ? profile?.department
                      ? `You see reports routed to ${profile.department}, and decide what happens to them.`
                      : 'You see reports across every department, and decide what happens to them.'
                    : 'You see problems the government has released for collaboration, and can express interest in them.'}
                </p>
              </div>
            </div>

            <dl>
              <DataRow label="Email" mono>
                {user?.email}
              </DataRow>
              <DataRow label="Role" mono>
                {role}
              </DataRow>
              {role === 'government' ? (
                <DataRow label="Department">{profile?.department ?? 'All departments'}</DataRow>
              ) : (
                <DataRow label="Organisation">{profile?.organization ?? 'Not set'}</DataRow>
              )}
              <DataRow label="Account created" mono>
                {formatDate(profile?.created_at)}
              </DataRow>
            </dl>

            <p className="mt-4 text-xs text-mute">
              Role, department and organisation are set by an administrator in Supabase — they are
              not editable here, because they control what you can see.
            </p>
          </Panel>

          <Panel title="Session">
            <p className="text-sm text-ash">
              Signing out clears this browser. You will need your email and password again.
            </p>
            <button type="button" onClick={signOut} className="btn-outline mt-4">
              Sign out
            </button>
          </Panel>
        </div>
      </div>
    </>
  )
}
