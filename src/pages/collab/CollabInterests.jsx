import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'
import { listMyInterests, withdrawInterest } from '../../lib/api'
import { useAsync } from '../../hooks/useAsync'
import { roleMeta, formatDateTime } from '../../lib/constants'
import {
  PageHeader,
  Panel,
  LoadingBlock,
  ErrorNote,
  EmptyState,
  StatusChip,
  PriorityChip,
} from '../../components/ui'
import ProblemImage from '../../components/ProblemImage'
import { IconHand, IconArrowRight } from '../../components/Icons'

export default function CollabInterests() {
  const { profile, role } = useAuth()
  const home = roleMeta(role)?.home ?? '/'
  const { data, error, loading, reload } = useAsync(listMyInterests, [])
  const [busyId, setBusyId] = useState(null)
  const [actionError, setActionError] = useState(null)

  const rows = (data ?? []).filter((r) => r.problem)
  const orgName = profile?.organization || profile?.full_name || 'Your organisation'

  async function drop(interestId) {
    setBusyId(interestId)
    setActionError(null)
    try {
      await withdrawInterest(interestId)
      reload()
    } catch (err) {
      setActionError(err?.message ?? 'Interest could not be withdrawn.')
    } finally {
      setBusyId(null)
    }
  }

  return (
    <>
      <PageHeader
        eyebrow={`${roleMeta(role)?.label ?? ''} · ${orgName}`}
        title="Our interests"
        description="Challenges you have offered to work on. The owning department can see each of these."
      />

      <ErrorNote onRetry={reload}>{error}</ErrorNote>
      <ErrorNote>{actionError}</ErrorNote>

      <Panel bodyClass="">
        {loading ? (
          <LoadingBlock label="Loading your interests" />
        ) : rows.length ? (
          <ul>
            {rows.map((row) => {
              const p = row.problem
              return (
                <li
                  key={row.id}
                  className="flex flex-col gap-4 border-b border-line p-5 last:border-b-0 sm:flex-row"
                >
                  <Link to={`${home}/challenges/${p.id}`} className="w-full shrink-0 sm:w-40">
                    <ProblemImage src={p.image_url} alt={p.title} ratio="aspect-[16/10]" />
                  </Link>

                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="ticket">{p.ticket_no}</span>
                      <span className="font-mono text-2xs text-mute">
                        · sent {formatDateTime(row.created_at)}
                      </span>
                    </div>

                    <Link
                      to={`${home}/challenges/${p.id}`}
                      className="mt-1 block text-sm font-semibold text-ink hover:text-brand-dark"
                    >
                      {p.title || 'Untitled challenge'}
                    </Link>

                    <p className="mt-1 text-xs text-ash">
                      {p.department ?? 'Department'} · {p.address || 'Coordinates only'}
                    </p>

                    {row.note ? (
                      <p className="mt-2.5 rounded-md border border-line bg-paper px-3 py-2 text-xs text-ash">
                        “{row.note}”
                      </p>
                    ) : null}

                    <div className="mt-3 flex flex-wrap items-center gap-2">
                      <PriorityChip value={p.priority} />
                      <StatusChip value={p.status} />
                    </div>
                  </div>

                  <div className="flex shrink-0 flex-col items-stretch gap-2 sm:w-36">
                    <Link to={`${home}/challenges/${p.id}`} className="btn-outline btn-sm">
                      Open
                      <IconArrowRight width={13} height={13} />
                    </Link>
                    <button
                      type="button"
                      onClick={() => drop(row.id)}
                      disabled={busyId === row.id}
                      className="btn-ghost btn-sm"
                    >
                      {busyId === row.id ? 'Withdrawing' : 'Withdraw'}
                    </button>
                  </div>
                </li>
              )
            })}
          </ul>
        ) : (
          <EmptyState
            icon={IconHand}
            title="You have not taken anything on yet"
            action={
              <Link to={`${home}/challenges`} className="btn-primary">
                Browse open challenges
              </Link>
            }
          >
            When you express interest in a released problem, it appears here and the department is
            notified.
          </EmptyState>
        )}
      </Panel>
    </>
  )
}
