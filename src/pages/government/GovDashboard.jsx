import { Link } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'
import { listDepartmentProblems } from '../../lib/api'
import { useAsync } from '../../hooks/useAsync'
import { priorityWeight } from '../../lib/constants'
import { PageHeader, Panel, LoadingBlock, ErrorNote, EmptyState } from '../../components/ui'
import ProblemTable from '../../components/ProblemTable'
import { IconInbox, IconRefresh, IconArrowRight } from '../../components/Icons'

const HOME = '/government'

/** Counts the government user actually cares about, computed from one query. */
function summarise(problems) {
  const awaiting = problems.filter((p) => p.status === 'submitted' || p.status === 'under_review')
  const released = problems.filter((p) =>
    ['released', 'interest_expressed', 'in_progress'].includes(p.status)
  )
  const internal = problems.filter((p) => p.status === 'government_handling')
  const resolved = problems.filter((p) => p.status === 'resolved')
  return { awaiting, released, internal, resolved }
}

function StatCard({ label, value, hint, tone = 'text-ink', to }) {
  const body = (
    <div className="card h-full p-5 transition-shadow hover:shadow-lift">
      <p className="eyebrow">{label}</p>
      <p className={`mt-2 font-display text-3xl font-semibold tracking-tight ${tone}`}>{value}</p>
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

export default function GovDashboard() {
  const { profile } = useAuth()
  const { data, error, loading, reload } = useAsync(listDepartmentProblems, [])
  const problems = data ?? []
  const { awaiting, released, internal, resolved } = summarise(problems)

  // The triage list: newest and most urgent of what still needs a decision.
  const needsDecision = [...awaiting].sort(
    (a, b) =>
      priorityWeight(b.priority) - priorityWeight(a.priority) ||
      new Date(b.created_at) - new Date(a.created_at)
  )

  const deptLabel = profile?.department || 'All departments'

  return (
    <>
      <PageHeader
        eyebrow={`Government · ${deptLabel}`}
        title="Department control desk"
        description="Every citizen report routed to your department. Decide what your office handles, and what you open to universities and industry."
        actions={
          <button type="button" onClick={reload} className="btn-outline btn-sm">
            <IconRefresh width={14} height={14} />
            Refresh
          </button>
        }
      />

      <ErrorNote onRetry={reload}>{error}</ErrorNote>

      {loading ? (
        <LoadingBlock label="Loading your department queue" />
      ) : (
        <>
          <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
            <StatCard
              label="Awaiting decision"
              value={awaiting.length}
              hint="New + under review"
              tone={awaiting.length ? 'text-crit' : 'text-ink'}
              to={`${HOME}/problems?group=awaiting`}
            />
            <StatCard
              label="Released"
              value={released.length}
              hint="Open for collaboration"
              tone="text-univ"
              to={`${HOME}/problems?group=released`}
            />
            <StatCard
              label="Handling in-house"
              value={internal.length}
              hint="Kept by the department"
              tone="text-brand-dark"
              to={`${HOME}/problems?group=internal`}
            />
            <StatCard
              label="Resolved"
              value={resolved.length}
              hint="Closed out"
              to={`${HOME}/problems?group=resolved`}
            />
          </div>

          <div className="mt-6">
            <Panel
              title="Needs your decision"
              subtitle={
                needsDecision.length
                  ? 'Highest priority first — open one to release it or keep it in-house.'
                  : undefined
              }
              actions={
                <Link to={`${HOME}/problems`} className="btn-ghost btn-sm">
                  All problems
                  <IconArrowRight width={13} height={13} />
                </Link>
              }
              bodyClass=""
            >
              {needsDecision.length ? (
                <ProblemTable problems={needsDecision.slice(0, 8)} basePath={`${HOME}/problems`} />
              ) : (
                <EmptyState icon={IconInbox} title="Nothing waiting on you">
                  Every report in {deptLabel} has been actioned. New citizen submissions will appear
                  here automatically.
                </EmptyState>
              )}
            </Panel>
          </div>
        </>
      )}
    </>
  )
}
