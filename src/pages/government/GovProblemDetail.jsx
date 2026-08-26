import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'
import {
  getProblem,
  listInterestsForProblem,
  markUnderReview,
  decideProblem,
  setProblemStatus,
  rejectProblem,
} from '../../lib/api'
import { useAsync } from '../../hooks/useAsync'
import { formatDateTime, statusMeta, scopeMeta } from '../../lib/constants'
import {
  PageHeader,
  Panel,
  DataRow,
  LoadingBlock,
  ErrorNote,
  EmptyState,
  StatusChip,
  PriorityChip,
  CategoryChip,
  ScopeChip,
  LocationLine,
  Spinner,
} from '../../components/ui'
import CustodyTrack from '../../components/CustodyTrack'
import ProblemImage from '../../components/ProblemImage'
import {
  IconArrowLeft,
  IconCheck,
  IconLandmark,
  IconCap,
  IconFactory,
  IconHand,
} from '../../components/Icons'

const HOME = '/government'

const DECISIONS = [
  {
    key: 'internal',
    label: 'Handle internally',
    detail: 'Your department takes this on. It stays out of the collaboration boards.',
    icon: IconLandmark,
    accent: 'text-brand',
  },
  {
    key: 'university',
    label: 'Release to universities',
    detail: 'University representatives can see it and offer to work on it.',
    icon: IconCap,
    accent: 'text-univ',
  },
  {
    key: 'industry',
    label: 'Release to industry',
    detail: 'Industry representatives can see it and offer to work on it.',
    icon: IconFactory,
    accent: 'text-ind',
  },
  {
    key: 'both',
    label: 'Release to both',
    detail: 'Open to universities and industry at the same time.',
    icon: IconHand,
    accent: 'text-ink',
  },
]

const REJECTION_PRESETS = [
  'Not a public infrastructure issue',
  'Duplicate of an existing active report',
  'Insufficient / unclear photographic evidence',
  'Outside department jurisdiction',
  'Invalid or test submission',
]

const AWAITING = ['submitted', 'under_review']

export default function GovProblemDetail() {
  const { id } = useParams()
  const { user } = useAuth()

  const problemQuery = useAsync(() => getProblem(id), [id])
  const interestsQuery = useAsync(() => listInterestsForProblem(id), [id])

  const problem = problemQuery.data
  const interests = interestsQuery.data ?? []

  const [choice, setChoice] = useState(null)
  const [note, setNote] = useState('')
  const [revising, setRevising] = useState(false)
  const [rejecting, setRejecting] = useState(false)
  const [rejectionReason, setRejectionReason] = useState('')
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState(null)

  // Opening a brand-new report is what puts it under review.
  useEffect(() => {
    if (problem?.status === 'submitted') {
      markUnderReview(problem.id)
        .then(() => problemQuery.setData({ ...problem, status: 'under_review' }))
        .catch(() => {})
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [problem?.id, problem?.status])

  useEffect(() => {
    if (problem?.government_note) setNote(problem.government_note)
  }, [problem?.government_note])

  async function submitDecision() {
    if (!choice || !problem) return
    setSaving(true)
    setSaveError(null)
    try {
      const updated = await decideProblem(problem.id, choice, note, user?.id)
      problemQuery.setData(updated ?? { ...problem })
      setChoice(null)
      setRevising(false)
      setRejecting(false)
    } catch (err) {
      setSaveError(err?.message ?? 'The decision could not be saved.')
    } finally {
      setSaving(false)
    }
  }

  async function submitRejection() {
    if (!problem) return
    const reason = rejectionReason.trim()
    if (!reason) {
      setSaveError('Please select or specify a reason for rejecting this report.')
      return
    }
    setSaving(true)
    setSaveError(null)
    try {
      const updated = await rejectProblem(problem.id, reason, user?.id)
      problemQuery.setData(
        updated ?? {
          ...problem,
          status: 'rejected',
          rejection_reason: reason,
          rejected_at: new Date().toISOString(),
        }
      )
      setRejecting(false)
      setChoice(null)
      setRevising(false)
    } catch (err) {
      setSaveError(err?.message ?? 'The report could not be rejected.')
    } finally {
      setSaving(false)
    }
  }

  async function advance(status) {
    if (!problem) return
    setSaving(true)
    setSaveError(null)
    try {
      const updated = await setProblemStatus(problem.id, status)
      problemQuery.setData(updated ?? { ...problem, status })
    } catch (err) {
      setSaveError(err?.message ?? 'The status could not be updated.')
    } finally {
      setSaving(false)
    }
  }

  if (problemQuery.loading) return <LoadingBlock label="Opening report" />

  if (problemQuery.error || !problem) {
    return (
      <>
        <BackLink />
        <ErrorNote onRetry={problemQuery.reload}>
          {problemQuery.error ?? 'This report is not in your department, or it no longer exists.'}
        </ErrorNote>
      </>
    )
  }

  const awaiting = AWAITING.includes(problem.status)
  const decided = !awaiting
  const showChoices = awaiting || revising
  const released = ['released', 'interest_expressed', 'in_progress'].includes(problem.status)

  return (
    <>
      <BackLink />

      <PageHeader
        eyebrow={`${problem.ticket_no ?? 'Report'} · ${problem.department ?? 'Unassigned'}`}
        title={problem.title || 'Untitled report'}
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <PriorityChip value={problem.priority} />
            <StatusChip value={problem.status} />
          </div>
        }
      />

      <div className="card mb-6 px-5 py-4">
        <CustodyTrack status={problem.status} />
      </div>

      <div className="grid gap-5 lg:grid-cols-[minmax(0,1.55fr)_minmax(0,1fr)]">
        {/* ------------------------------ left: the report ------------------------------ */}
        <div className="space-y-5">
          <Panel title="Citizen evidence" subtitle="Photograph submitted from the mobile app">
            <ProblemImage src={problem.image_url} alt={problem.title} />
            <div className="mt-4 flex flex-wrap gap-2">
              <CategoryChip value={problem.category} />
              <ScopeChip value={problem.released_to} />
            </div>
          </Panel>

          <Panel title="What was reported">
            <p className="whitespace-pre-line text-sm leading-relaxed text-ink">
              {problem.description || 'No description was generated for this report.'}
            </p>
            <div className="mt-5 border-t border-line pt-4">
              <p className="eyebrow mb-2">Location</p>
              <LocationLine
                address={problem.address}
                latitude={problem.latitude}
                longitude={problem.longitude}
              />
            </div>
          </Panel>

          <Panel title="Interest from partners" subtitle="Organisations that asked to work on this" bodyClass="">
            {interestsQuery.loading ? (
              <LoadingBlock label="Checking interest" />
            ) : interests.length ? (
              <ul>
                {interests.map((it) => (
                  <li
                    key={it.id}
                    className="flex items-start justify-between gap-4 border-b border-line px-5 py-3.5 last:border-b-0"
                  >
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-ink">{it.org_name}</p>
                      <p className="mt-0.5 font-mono text-2xs uppercase tracking-[0.1em] text-mute">
                        {it.org_type} · {formatDateTime(it.created_at)}
                      </p>
                      {it.note ? <p className="mt-1.5 text-sm text-ash">{it.note}</p> : null}
                    </div>
                    <span className="chip border-line bg-paper text-ash">{it.status}</span>
                  </li>
                ))}
              </ul>
            ) : (
              <EmptyState icon={IconHand} title="No interest yet">
                {released
                  ? 'This is visible on the collaboration boards. Interest will show up here.'
                  : 'Release this problem for universities or industry to make it visible to them.'}
              </EmptyState>
            )}
          </Panel>
        </div>

        {/* ------------------------------ right: the decision ------------------------------ */}
        <div className="space-y-5 lg:sticky lg:top-6 lg:self-start">
          <Panel
            title={
              rejecting
                ? 'Reject report'
                : problem.status === 'rejected'
                ? 'Report rejected'
                : showChoices
                ? 'Your decision'
                : 'Decision on record'
            }
            subtitle={
              rejecting
                ? 'State the reason for rejecting this citizen submission.'
                : problem.status === 'rejected'
                ? undefined
                : showChoices
                ? 'Choose one. This is what makes a problem visible to partners.'
                : undefined
            }
          >
            {rejecting ? (
              <div className="space-y-3">
                <p className="text-xs text-ash">
                  Select or type the official reason. Rejected reports are kept for 1 hour before permanent deletion.
                </p>

                <div className="flex flex-wrap gap-1.5">
                  {REJECTION_PRESETS.map((preset) => {
                    const isSelected = rejectionReason === preset
                    return (
                      <button
                        key={preset}
                        type="button"
                        onClick={() => setRejectionReason(preset)}
                        className={[
                          'rounded border px-2.5 py-1 text-xs text-left transition-colors',
                          isSelected
                            ? 'border-crit bg-crit text-white font-medium'
                            : 'border-line bg-surface text-ash hover:border-ash hover:text-ink',
                        ].join(' ')}
                      >
                        {preset}
                      </button>
                    )
                  })}
                </div>

                <div className="mt-2">
                  <label htmlFor="rejection-custom" className="field-label">
                    Rejection note
                  </label>
                  <textarea
                    id="rejection-custom"
                    rows={2}
                    value={rejectionReason}
                    onChange={(e) => setRejectionReason(e.target.value)}
                    placeholder="Enter or customize reason..."
                    className="input resize-y text-xs"
                  />
                </div>

                <ErrorNote>{saveError}</ErrorNote>

                <div className="mt-3 flex items-center gap-2">
                  <button
                    type="button"
                    onClick={submitRejection}
                    disabled={saving || !rejectionReason.trim()}
                    className="btn bg-crit text-white hover:bg-crit/90 flex-1 btn-sm"
                  >
                    {saving ? <Spinner /> : null}
                    {saving ? 'Rejecting' : 'Confirm rejection'}
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setRejecting(false)
                      setRejectionReason('')
                      setSaveError(null)
                    }}
                    className="btn-outline btn-sm"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : problem.status === 'rejected' ? (
              <div className="space-y-4">
                <div className="rounded-md border border-crit/30 bg-crit/5 p-4">
                  <p className="text-2xs font-mono uppercase tracking-[0.1em] text-crit font-semibold">
                    Rejection Reason
                  </p>
                  <p className="mt-1 text-sm font-medium text-ink">
                    {problem.rejection_reason || 'Report rejected by department.'}
                  </p>
                  <p className="mt-2 text-2xs text-mute font-mono">
                    Rejected on {problem.rejected_at ? formatDateTime(problem.rejected_at) : formatDateTime(problem.updated_at)}
                  </p>
                </div>

                <p className="rounded-md border border-line bg-paper px-3 py-2 text-xs text-ash leading-relaxed">
                  ⚠️ This report is rejected and will be permanently deleted from the database 1 hour after rejection.
                </p>

                <ErrorNote>{saveError}</ErrorNote>

                <button
                  type="button"
                  onClick={() => {
                    setRevising(true)
                    setChoice(null)
                    setSaveError(null)
                  }}
                  className="btn-outline w-full text-xs"
                >
                  Reconsider / Change decision
                </button>
              </div>
            ) : showChoices ? (
              <>
                <div className="space-y-2">
                  {DECISIONS.map((d) => {
                    const active = choice === d.key
                    return (
                      <button
                        key={d.key}
                        type="button"
                        onClick={() => setChoice(d.key)}
                        aria-pressed={active}
                        className={[
                          'flex w-full items-start gap-3 rounded-md border px-3.5 py-3 text-left transition-colors',
                          active
                            ? 'border-brand bg-brand-tint'
                            : 'border-line bg-surface hover:border-ash hover:bg-paper',
                        ].join(' ')}
                      >
                        <d.icon
                          width={16}
                          height={16}
                          className={`mt-0.5 shrink-0 ${active ? 'text-brand-dark' : d.accent}`}
                        />
                        <span className="min-w-0">
                          <span className="block text-sm font-medium text-ink">{d.label}</span>
                          <span className="mt-0.5 block text-xs leading-relaxed text-ash">
                            {d.detail}
                          </span>
                        </span>
                        {active ? (
                          <IconCheck width={15} height={15} className="ml-auto mt-0.5 text-brand-dark" />
                        ) : null}
                      </button>
                    )
                  })}
                </div>

                <div className="mt-4">
                  <label htmlFor="note" className="field-label">
                    Note for partners <span className="normal-case tracking-normal">(optional)</span>
                  </label>
                  <textarea
                    id="note"
                    rows={3}
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                    placeholder="What kind of help would be most useful here?"
                    className="input resize-y"
                  />
                </div>

                <ErrorNote>{saveError}</ErrorNote>

                <div className="mt-4 flex items-center gap-2">
                  <button
                    type="button"
                    onClick={submitDecision}
                    disabled={!choice || saving}
                    className="btn-primary flex-1"
                  >
                    {saving ? <Spinner /> : null}
                    {saving ? 'Saving' : 'Confirm decision'}
                  </button>
                  {revising ? (
                    <button
                      type="button"
                      onClick={() => {
                        setRevising(false)
                        setChoice(null)
                      }}
                      className="btn-outline"
                    >
                      Cancel
                    </button>
                  ) : null}
                </div>

                <div className="mt-3 border-t border-line pt-3">
                  <button
                    type="button"
                    onClick={() => {
                      setRejecting(true)
                      setSaveError(null)
                    }}
                    className="btn-ghost text-crit w-full text-xs hover:bg-crit/5"
                  >
                    Reject this report
                  </button>
                </div>
              </>
            ) : (
              <>
                <p className="text-sm text-ink">{statusMeta(problem.status).description}</p>
                <dl className="mt-4">
                  <DataRow label="Released to">{scopeMeta(problem.released_to).label}</DataRow>
                  <DataRow label="Decided on" mono>
                    {problem.released_at ? formatDateTime(problem.released_at) : formatDateTime(problem.updated_at)}
                  </DataRow>
                  {problem.resolved_at ? (
                    <DataRow label="Resolved on" mono>
                      {formatDateTime(problem.resolved_at)}
                    </DataRow>
                  ) : null}
                  {problem.government_note ? (
                    <DataRow label="Note for partners">{problem.government_note}</DataRow>
                  ) : null}
                </dl>
                {problem.status === 'resolved' ? (
                  <p className="mt-3 rounded-md border border-line bg-paper px-3 py-2 text-xs text-ash">
                    Resolved reports are automatically archived and removed after 24 hours.
                  </p>
                ) : null}

                <ErrorNote>{saveError}</ErrorNote>

                <div className="mt-4 space-y-2">
                  {problem.status !== 'resolved' && problem.status !== 'in_progress' ? (
                    <button
                      type="button"
                      onClick={() => advance('in_progress')}
                      disabled={saving}
                      className="btn-outline w-full"
                    >
                      Mark work started
                    </button>
                  ) : null}
                  {problem.status !== 'resolved' ? (
                    <button
                      type="button"
                      onClick={() => advance('resolved')}
                      disabled={saving}
                      className="btn-ink w-full"
                    >
                      Mark resolved
                    </button>
                  ) : null}
                  <button
                    type="button"
                    onClick={() => {
                      setRevising(true)
                      setChoice(null)
                    }}
                    className="btn-ghost w-full"
                  >
                    Change the decision
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setRejecting(true)
                      setSaveError(null)
                    }}
                    className="btn-ghost text-crit w-full text-xs hover:bg-crit/5"
                  >
                    Reject report
                  </button>
                </div>
              </>
            )}
          </Panel>

          <Panel title="Report details">
            <dl>
              <DataRow label="Reference" mono>
                {problem.ticket_no}
              </DataRow>
              <DataRow label="Category">{problem.category ?? 'Uncategorised'}</DataRow>
              <DataRow label="Department">{problem.department ?? 'Unassigned'}</DataRow>
              <DataRow label="Reported by">{problem.reporter_name || 'Citizen (mobile app)'}</DataRow>
              <DataRow label="Received" mono>
                {formatDateTime(problem.created_at)}
              </DataRow>
              {problem.duplicate_of ? (
                <DataRow label="Duplicate of" mono>
                  <Link
                    to={`${HOME}/problems/${problem.duplicate_of}`}
                    className="text-brand hover:underline"
                  >
                    View the original report
                  </Link>
                </DataRow>
              ) : null}
            </dl>
          </Panel>
        </div>
      </div>
    </>
  )
}

function BackLink() {
  return (
    <Link
      to={`${HOME}/problems`}
      className="mb-4 inline-flex items-center gap-2 font-mono text-2xs uppercase tracking-[0.12em] text-mute transition-colors hover:text-ink"
    >
      <IconArrowLeft width={14} height={14} />
      All problems
    </Link>
  )
}
