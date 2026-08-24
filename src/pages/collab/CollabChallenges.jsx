import { useMemo, useState } from 'react'
import { useAuth } from '../../context/AuthContext'
import { listReleasedProblems, listMyInterestIds } from '../../lib/api'
import { useAsync } from '../../hooks/useAsync'
import { useTableChanges } from '../../hooks/useRealtime'
import { roleMeta, PRIORITY, priorityWeight } from '../../lib/constants'
import { PageHeader, Panel, LoadingBlock, ErrorNote, EmptyState } from '../../components/ui'
import ProblemCard from '../../components/ProblemCard'
import { IconInbox, IconSearch, IconRefresh } from '../../components/Icons'

export default function CollabChallenges() {
  const { role } = useAuth()
  const home = roleMeta(role)?.home ?? '/'

  const { data, error, loading, reload } = useAsync(async () => {
    const [problems, mine] = await Promise.all([listReleasedProblems(role), listMyInterestIds()])
    return { problems, interested: new Set(mine.map((m) => m.problem_id)) }
  }, [role])

  useTableChanges('problems', reload, 'collab-challenges-problems')

  const [query, setQuery] = useState('')
  const [priority, setPriority] = useState('all')
  const [view, setView] = useState('all') // all | new | mine
  const [sort, setSort] = useState('priority') // priority | recent

  const problems = data?.problems ?? []
  const interested = data?.interested ?? new Set()

  const categories = useMemo(
    () => Array.from(new Set(problems.map((p) => p.category).filter(Boolean))),
    [problems]
  )

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase()
    return problems
      .filter((p) => (view === 'mine' ? interested.has(p.id) : view === 'new' ? !interested.has(p.id) : true))
      .filter((p) => priority === 'all' || p.priority === priority)
      .filter(
        (p) =>
          !q ||
          p.title?.toLowerCase().includes(q) ||
          p.description?.toLowerCase().includes(q) ||
          p.address?.toLowerCase().includes(q) ||
          p.category?.toLowerCase().includes(q)
      )
      .sort((a, b) =>
        sort === 'recent'
          ? new Date(b.released_at ?? b.created_at) - new Date(a.released_at ?? a.created_at)
          : priorityWeight(b.priority) - priorityWeight(a.priority) ||
            new Date(b.released_at ?? b.created_at) - new Date(a.released_at ?? a.created_at)
      )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [problems, interested, query, priority, view, sort])

  const VIEWS = [
    { key: 'all', label: 'All open' },
    { key: 'new', label: 'Not yet actioned' },
    { key: 'mine', label: 'Interest sent' },
  ]

  return (
    <>
      <PageHeader
        eyebrow={roleMeta(role)?.label}
        title="Open challenges"
        description="Released problems you can voluntarily take up. Open one to see the full report before deciding."
        actions={
          <button type="button" onClick={reload} className="btn-outline btn-sm">
            <IconRefresh width={14} height={14} />
            Refresh
          </button>
        }
      />

      <ErrorNote onRetry={reload}>{error}</ErrorNote>

      <div className="mb-4 flex flex-wrap gap-1.5">
        {VIEWS.map((v) => {
          const active = v.key === view
          const n =
            v.key === 'mine'
              ? problems.filter((p) => interested.has(p.id)).length
              : v.key === 'new'
                ? problems.filter((p) => !interested.has(p.id)).length
                : problems.length
          return (
            <button
              key={v.key}
              type="button"
              onClick={() => setView(v.key)}
              className={[
                'inline-flex items-center gap-2 rounded-md border px-3 py-1.5 text-xs font-medium transition-colors',
                active
                  ? 'border-ink bg-ink text-white'
                  : 'border-line bg-surface text-ash hover:border-ash hover:text-ink',
              ].join(' ')}
            >
              {v.label}
              <span className={`font-mono text-2xs ${active ? 'text-white/60' : 'text-mute'}`}>{n}</span>
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
              placeholder="Search title, description, location…"
              className="input pl-9"
            />
          </div>
          <select value={priority} onChange={(e) => setPriority(e.target.value)} className="input w-auto" aria-label="Priority">
            <option value="all">All priorities</option>
            {Object.entries(PRIORITY).map(([key, meta]) => (
              <option key={key} value={key}>
                {meta.label}
              </option>
            ))}
          </select>
          <select value={sort} onChange={(e) => setSort(e.target.value)} className="input w-auto" aria-label="Sort by">
            <option value="priority">Priority first</option>
            <option value="recent">Most recent</option>
          </select>
        </div>

        <div className="p-5">
          {loading ? (
            <LoadingBlock label="Loading challenges" />
          ) : visible.length ? (
            <>
              {categories.length ? (
                <p className="mb-4 text-xs text-mute">
                  Showing {visible.length} of {problems.length} released ·{' '}
                  {categories.slice(0, 4).join(' · ')}
                  {categories.length > 4 ? ' · …' : ''}
                </p>
              ) : null}
              <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                {visible.map((p) => (
                  <ProblemCard
                    key={p.id}
                    problem={p}
                    to={`${home}/challenges/${p.id}`}
                    interested={interested.has(p.id)}
                  />
                ))}
              </div>
            </>
          ) : (
            <EmptyState icon={IconInbox} title="No challenges match">
              {problems.length
                ? 'Try a different filter or search.'
                : 'The government has not released anything yet. New challenges appear here automatically.'}
            </EmptyState>
          )}
        </div>
      </Panel>
    </>
  )
}
