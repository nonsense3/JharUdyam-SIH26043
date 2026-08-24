import { Link } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'
import { listReleasedProblems, listMyInterestIds } from '../../lib/api'
import { useAsync } from '../../hooks/useAsync'
import { useTableChanges } from '../../hooks/useRealtime'
import { roleMeta, priorityWeight } from '../../lib/constants'
import { PageHeader, Panel, LoadingBlock, ErrorNote, EmptyState } from '../../components/ui'
import ProblemCard from '../../components/ProblemCard'
import { IconInbox, IconArrowRight, IconRefresh } from '../../components/Icons'

export default function CollabDashboard() {
  const { profile, role } = useAuth()
  const home = roleMeta(role)?.home ?? '/'

  const { data, error, loading, reload } = useAsync(async () => {
    const [problems, mine] = await Promise.all([listReleasedProblems(role), listMyInterestIds()])
    return { problems, interested: new Set(mine.map((m) => m.problem_id)) }
  }, [role])

  useTableChanges('problems', reload, 'collab-dashboard-problems')

  const problems = data?.problems ?? []
  const interested = data?.interested ?? new Set()

  const open = problems.filter((p) => !interested.has(p.id))
  const active = problems.filter((p) => p.status === 'in_progress')

  const latest = [...open]
    .sort(
      (a, b) =>
        priorityWeight(b.priority) - priorityWeight(a.priority) ||
        new Date(b.released_at ?? b.created_at) - new Date(a.released_at ?? a.created_at)
    )
    .slice(0, 3)

  const orgName = profile?.organization || profile?.full_name || 'your organisation'
  const partnerWord = role === 'university' ? 'research teams' : 'engineering teams'

  return (
    <>
      <PageHeader
        eyebrow={`${roleMeta(role)?.label ?? ''} · ${orgName}`}
        title={role === 'university' ? 'Research collaboration board' : 'Partnership opportunities'}
        description={`Problems the government has opened up for outside help. Nothing here is assigned to you — pick what suits your ${partnerWord}.`}
        actions={
          <button type="button" onClick={reload} className="btn-outline btn-sm">
            <IconRefresh width={14} height={14} />
            Refresh
          </button>
        }
      />

      <ErrorNote onRetry={reload}>{error}</ErrorNote>

      {loading ? (
        <LoadingBlock label="Loading released challenges" />
      ) : (
        <>
          <div className="grid grid-cols-3 gap-3">
            <Stat label="Open to you" value={problems.length} hint="Released by government" to={`${home}/challenges`} />
            <Stat label="Interest sent" value={interested.size} hint="Awaiting government" to={`${home}/interests`} />
            <Stat label="Work underway" value={active.length} hint="Marked in progress" />
          </div>

          <div className="mt-6">
            <Panel
              title="Newest for you"
              subtitle={latest.length ? 'Highest priority first' : undefined}
              actions={
                <Link to={`${home}/challenges`} className="btn-ghost btn-sm">
                  Browse all
                  <IconArrowRight width={13} height={13} />
                </Link>
              }
              bodyClass={latest.length ? 'p-5' : ''}
            >
              {latest.length ? (
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                  {latest.map((p) => (
                    <ProblemCard key={p.id} problem={p} to={`${home}/challenges/${p.id}`} />
                  ))}
                </div>
              ) : (
                <EmptyState icon={IconInbox} title="Nothing new right now">
                  {problems.length
                    ? 'You have registered interest in everything currently open. Well done.'
                    : 'The government has not released any problems yet. They appear here the moment a department opens one up.'}
                </EmptyState>
              )}
            </Panel>
          </div>
        </>
      )}
    </>
  )
}

function Stat({ label, value, hint, to }) {
  const body = (
    <div className="card h-full p-5 transition-shadow hover:shadow-lift">
      <p className="eyebrow">{label}</p>
      <p className="mt-2 font-display text-3xl font-semibold tracking-tight text-ink">{value}</p>
      <p className="mt-1 flex items-center gap-1 text-xs text-ash">
        {hint}
        {to ? <IconArrowRight width={12} height={12} className="text-mute" /> : null}
      </p>
    </div>
  )
  return to ? (
    <Link to={to} className="block focus-visible:rounded-lg">
      {body}
    </Link>
  ) : (
    body
  )
}
