// ---------------------------------------------------------------------------
// Shared vocabulary for the interface: how each status, priority and role is
// spelled and coloured. Keep the wording here so every screen agrees.
// ---------------------------------------------------------------------------

export const STATUS = {
  submitted: {
    label: 'Submitted',
    short: 'New',
    className: 'border-line bg-paper text-ash',
    dot: 'bg-mute',
    description: 'Received from a citizen and waiting for the department to open it.',
  },
  under_review: {
    label: 'Under review',
    short: 'Reviewing',
    className: 'border-med/30 bg-med/10 text-med',
    dot: 'bg-med',
    description: 'The department has opened this report and is deciding what to do.',
  },
  government_handling: {
    label: 'Government handling',
    short: 'In-house',
    className: 'border-gov/30 bg-brand-tint text-brand-dark',
    dot: 'bg-brand',
    description: 'The department is handling this internally. It is not open for collaboration.',
  },
  released: {
    label: 'Released',
    short: 'Released',
    className: 'border-univ/30 bg-univ/10 text-univ',
    dot: 'bg-univ',
    description: 'Open for collaboration. Universities and industries can express interest.',
  },
  interest_expressed: {
    label: 'Interest expressed',
    short: 'Interest',
    className: 'border-ind/30 bg-ind/10 text-ind',
    dot: 'bg-ind',
    description: 'At least one organisation has offered to work on this.',
  },
  in_progress: {
    label: 'In progress',
    short: 'Active',
    className: 'border-high/30 bg-high/10 text-high',
    dot: 'bg-high',
    description: 'Work has started on this problem.',
  },
  resolved: {
    label: 'Resolved',
    short: 'Resolved',
    className: 'border-brand/30 bg-brand-tint text-brand-dark',
    dot: 'bg-brand',
    description: 'This problem has been dealt with.',
  },
}

export const PRIORITY = {
  critical: { label: 'Critical', className: 'border-crit/30 bg-crit/10 text-crit', bar: 'bg-crit', weight: 4 },
  high: { label: 'High', className: 'border-high/30 bg-high/10 text-high', bar: 'bg-high', weight: 3 },
  medium: { label: 'Medium', className: 'border-med/30 bg-med/10 text-med', bar: 'bg-med', weight: 2 },
  low: { label: 'Low', className: 'border-low/30 bg-low/10 text-low', bar: 'bg-low', weight: 1 },
}

export const RELEASE_SCOPE = {
  none: { label: 'Not released', className: 'border-line bg-paper text-mute' },
  university: { label: 'Universities', className: 'border-univ/30 bg-univ/10 text-univ' },
  industry: { label: 'Industry', className: 'border-ind/30 bg-ind/10 text-ind' },
  both: { label: 'Universities + industry', className: 'border-brand/30 bg-brand-tint text-brand-dark' },
}

export const ROLE = {
  government: {
    label: 'Government',
    home: '/government',
    accent: 'text-gov',
    accentBg: 'bg-gov',
    tagline: 'Department control desk',
  },
  university: {
    label: 'University',
    home: '/university',
    accent: 'text-univ',
    accentBg: 'bg-univ',
    tagline: 'Research collaboration board',
  },
  industry: {
    label: 'Industry',
    home: '/industry',
    accent: 'text-ind',
    accentBg: 'bg-ind',
    tagline: 'Partnership opportunity board',
  },
}

export const statusMeta = (key) => STATUS[key] ?? STATUS.submitted
export const priorityMeta = (key) => PRIORITY[key] ?? PRIORITY.medium
export const scopeMeta = (key) => RELEASE_SCOPE[key] ?? RELEASE_SCOPE.none
export const roleMeta = (key) => ROLE[key] ?? null

// Order used when sorting a queue by urgency.
export const priorityWeight = (key) => priorityMeta(key).weight

export function formatDate(value) {
  if (!value) return '—'
  return new Date(value).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

export function formatDateTime(value) {
  if (!value) return '—'
  return new Date(value).toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    hour: 'numeric',
    minute: '2-digit',
  })
}

export function timeAgo(value) {
  if (!value) return '—'
  const seconds = Math.floor((Date.now() - new Date(value).getTime()) / 1000)
  if (seconds < 60) return 'just now'
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  if (days < 30) return `${days}d ago`
  return formatDate(value)
}
