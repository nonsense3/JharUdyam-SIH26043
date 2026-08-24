import { useMemo, useState } from 'react'
import { listDepartmentProblems } from '../../lib/api'
import { useAsync } from '../../hooks/useAsync'
import { PRIORITY, priorityWeight } from '../../lib/constants'
import { PageHeader, Panel, LoadingBlock, ErrorNote, EmptyState } from '../../components/ui'
import ProblemTable from '../../components/ProblemTable'
import { IconInbox, IconSearch, IconRefresh } from '../../components/Icons'

const HOME = '/government'

const GROUPS = [
  { key: 'awaiting', label: 'Awaiting decision', match: (s) => s === 'submitted' || s === 'under_review' },
  { key: 'released', label: 'Released', match: (s) => ['released', 'interest_expressed', 'in_progress'].includes(s) },
  { key: 'internal', label: 'In-house', match: (s) => s === 'government_handling' },
  { key: 'resolved', label: 'Resolved', match: (s) => s === 'resolved' },
  { key: 'all', label: 'Everything', match: () => true },
]

export default function GovProblems() {
  const { data, error, loading, reload } = useAsync(listDepartmentProblems, [])
  const [group, setGroup] = useState('awaiting')
  const [priority, setPriority] = useState('all')
  const [query, setQuery] = useState('')

  const problems = data ?? []

  const counts = useMemo(() => {
    const c = {}
    for (const g of GROUPS) c[g.key] = problems.filter((p) => g.match(p.status)).length
    return c
  }, [problems])

  const visible = useMemo(() => {
    const g = GROUPS.find((x) => x.key === group) ?? GROUPS[0]
    const q = query.trim().toLowerCase()
    return problems
      .filter((p) => g.match(p.status))
      .filter((p) => priority === 'all' || p.priority === priority)
      .filter(
        (p) =>
          !q ||
          p.title?.toLowerCase().includes(q) ||
          p.address?.toLowerCase().includes(q) ||
          p.ticket_no?.toLowerCase().includes(q) ||
          p.category?.toLowerCase().includes(q)
      )
      .sort(
        (a, b) =>
          priorityWeight(b.priority) - priorityWeight(a.priority) ||
          new Date(b.created_at) - new Date(a.created_at)
      )
  }, [problems, group, priority, query])

  return (
    <>
      <PageHeader
        eyebrow="Government"
        title="Problems"
        description="The full queue for your department. Filter by where each report sits, then open one to act on it."
        actions={
          <button type="button" onClick={reload} className="btn-outline btn-sm">
            <IconRefresh width={14} height={14} />
            Refresh
          </button>
        }
      />

      <ErrorNote onRetry={reload}>{error}</ErrorNote>

      {/* status tabs */}
      <div className="mb-4 flex flex-wrap gap-1.5">
        {GROUPS.map((g) => {
          const active = g.key === group
          return (
            <button
              key={g.key}
              type="button"
              onClick={() => setGroup(g.key)}
              className={[
                'inline-flex items-center gap-2 rounded-md border px-3 py-1.5 text-xs font-medium transition-colors',
                active
                  ? 'border-ink bg-ink text-white'
                  : 'border-line bg-surface text-ash hover:border-ash hover:text-ink',
              ].join(' ')}
            >
              {g.label}
              <span
                className={`font-mono text-2xs ${active ? 'text-white/60' : 'text-mute'}`}
              >
                {counts[g.key] ?? 0}
              </span>
            </button>
          )
        })}
      </div>

      <Panel bodyClass="">
        <div className="flex flex-wrap items-center gap-3 border-b border-line px-4 py-3">
          <div className="relative min-w-[200px] flex-1">
            <IconSearch
              width={15}
              height={15}
              className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-mute"
            />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search reference, title, location…"
              className="input pl-9"
            />
          </div>
          <select
            value={priority}
            onChange={(e) => setPriority(e.target.value)}
            className="input w-auto"
            aria-label="Filter by priority"
          >
            <option value="all">All priorities</option>
            {Object.entries(PRIORITY).map(([key, meta]) => (
              <option key={key} value={key}>
                {meta.label}
              </option>
            ))}
          </select>
        </div>

        {loading ? (
          <LoadingBlock label="Loading problems" />
        ) : (
          <ProblemTable
            problems={visible}
            basePath={`${HOME}/problems`}
            emptyState={
              <EmptyState icon={IconInbox} title="No problems match">
                {query || priority !== 'all'
                  ? 'Try clearing the search or the priority filter.'
                  : 'Nothing in this group yet.'}
              </EmptyState>
            }
          />
        )}
      </Panel>
    </>
  )
}
