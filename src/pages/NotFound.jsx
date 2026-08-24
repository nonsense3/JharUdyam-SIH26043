import { Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { roleMeta } from '../lib/constants'

export default function NotFound() {
  const { role } = useAuth()
  const home = roleMeta(role)?.home ?? '/'

  return (
    <div className="card px-6 py-16 text-center">
      <p className="font-mono text-2xs uppercase tracking-[0.14em] text-mute">Page not found</p>
      <h1 className="mt-2 text-xl font-semibold text-ink">There is nothing at this address</h1>
      <p className="mx-auto mt-2 max-w-sm text-sm text-ash">
        The link may be out of date, or the page may belong to a different portal.
      </p>
      <Link to={home} className="btn-primary mt-6">
        Back to dashboard
      </Link>
    </div>
  )
}
