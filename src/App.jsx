import { Routes, Route, Navigate, Outlet } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import { isSupabaseConfigured } from './lib/supabase'
import { ProtectedRoute, RoleRedirect } from './components/Gate'
import AppLayout from './components/AppLayout'

import Landing from './pages/Landing'
import Login from './pages/Login'
import Register from './pages/Register'
import SetupNeeded from './pages/SetupNeeded'
import NotFound from './pages/NotFound'
import Notifications from './pages/Notifications'
import Profile from './pages/Profile'

import GovDashboard from './pages/government/GovDashboard'
import GovProblems from './pages/government/GovProblems'
import GovProblemDetail from './pages/government/GovProblemDetail'

import CollabDashboard from './pages/collab/CollabDashboard'
import CollabChallenges from './pages/collab/CollabChallenges'
import CollabChallengeDetail from './pages/collab/CollabChallengeDetail'
import CollabInterests from './pages/collab/CollabInterests'

/** Sidebar + page frame. Child routes render into the Outlet. */
function PortalShell({ allow }) {
  return (
    <ProtectedRoute allow={allow}>
      <AppLayout>
        <Outlet />
      </AppLayout>
    </ProtectedRoute>
  )
}

export default function App() {
  // No Supabase keys in .env yet — show the setup instructions instead of a
  // blank screen and a console error.
  if (!isSupabaseConfigured) return <SetupNeeded />

  return (
    <AuthProvider>
      <Routes>
        <Route path="/" element={<Landing />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />

        {/* ------------------------------- government ------------------------------- */}
        <Route path="/government" element={<PortalShell allow={['government']} />}>
          <Route index element={<GovDashboard />} />
          <Route path="problems" element={<GovProblems />} />
          <Route path="problems/:id" element={<GovProblemDetail />} />
          <Route path="notifications" element={<Notifications />} />
          <Route path="profile" element={<Profile />} />
          <Route path="*" element={<NotFound />} />
        </Route>

        {/* ------------------------------- university -------------------------------
            University and industry use the same screens — the signed-in role
            decides which released problems the database will hand over.        */}
        <Route path="/university" element={<PortalShell allow={['university']} />}>
          <Route index element={<CollabDashboard />} />
          <Route path="challenges" element={<CollabChallenges />} />
          <Route path="challenges/:id" element={<CollabChallengeDetail />} />
          <Route path="interests" element={<CollabInterests />} />
          <Route path="notifications" element={<Notifications />} />
          <Route path="profile" element={<Profile />} />
          <Route path="*" element={<NotFound />} />
        </Route>

        {/* -------------------------------- industry -------------------------------- */}
        <Route path="/industry" element={<PortalShell allow={['industry']} />}>
          <Route index element={<CollabDashboard />} />
          <Route path="challenges" element={<CollabChallenges />} />
          <Route path="challenges/:id" element={<CollabChallengeDetail />} />
          <Route path="interests" element={<CollabInterests />} />
          <Route path="notifications" element={<Notifications />} />
          <Route path="profile" element={<Profile />} />
          <Route path="*" element={<NotFound />} />
        </Route>

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AuthProvider>
  )
}
