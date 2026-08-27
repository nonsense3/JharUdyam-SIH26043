import { useState, useEffect } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import './Landing.css'

const APP_DOWNLOAD_URL = 'YOUR_APK_DOWNLOAD_URL'

export default function Landing() {
  const navigate = useNavigate()
  const [navOpen, setNavOpen] = useState(false)
  const [isScrolled, setIsScrolled] = useState(false)
  const [toastMessage, setToastMessage] = useState(null)

  useEffect(() => {
    const onScroll = () => setIsScrolled(window.scrollY > 8)
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  function showToast(msg) {
    setToastMessage(msg)
    setTimeout(() => {
      setToastMessage(null)
    }, 3200)
  }

  function handleAppClick() {
    if (!APP_DOWNLOAD_URL || APP_DOWNLOAD_URL.startsWith('YOUR_')) {
      showToast('The JharUdyam citizen app link is coming soon.')
      return
    }
    window.location.href = APP_DOWNLOAD_URL
  }

  function handlePortalClick() {
    navigate('/login')
  }

  function scrollToSection(e, id) {
    e.preventDefault()
    setNavOpen(false)
    const el = document.getElementById(id)
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  return (
    <div className="landing-root">
      {/* ============================ HEADER / NAV ============================ */}
      <header className={`site-header ${isScrolled ? 'is-scrolled' : ''}`} id="siteHeader">
        <div className="container header-inner">
          <a
            className="brand"
            href="#top"
            onClick={(e) => scrollToSection(e, 'top')}
            aria-label="JharUdyam home"
          >
            <picture>
              <source srcset="/assets/logo-emblem.webp" type="image/webp" />
              <img
                className="brand-mark"
                src="/assets/logo-emblem.png"
                alt="JharUdyam emblem"
                width="44"
                height="44"
              />
            </picture>
            <span className="brand-word">
              Jhar<span className="brand-word-accent">Udyam</span>
            </span>
          </a>

          <nav className={`nav ${navOpen ? 'nav-open' : ''}`} id="primaryNav" aria-label="Primary">
            <a href="#how" onClick={(e) => scrollToSection(e, 'how')}>
              How it works
            </a>
            <a href="#stakeholders" onClick={(e) => scrollToSection(e, 'stakeholders')}>
              Stakeholders
            </a>
            <a href="#ai" onClick={(e) => scrollToSection(e, 'ai')}>
              AI
            </a>
            <a href="#sih" onClick={(e) => scrollToSection(e, 'sih')}>
              SIH 2026
            </a>
            <div className="nav-cta">
              <Link to="/login" className="l-btn l-btn-ghost l-btn-sm">
                Partner Portal
              </Link>
              <button
                className="l-btn l-btn-primary l-btn-sm"
                type="button"
                onClick={handleAppClick}
              >
                Get the App
              </button>
            </div>
          </nav>

          <button
            className="nav-toggle"
            id="navToggle"
            type="button"
            aria-label="Toggle menu"
            aria-expanded={navOpen}
            onClick={() => setNavOpen(!navOpen)}
          >
            <span></span>
            <span></span>
            <span></span>
          </button>
        </div>
      </header>

      <main id="main">
        <span id="top"></span>

        {/* ================================ HERO ================================ */}
        <section className="hero" aria-labelledby="hero-title">
          <div className="container hero-grid">
            <div className="hero-copy">
              <p className="eyebrow-text">Government of Jharkhand · Smart India Hackathon 2026</p>
              <h1 id="hero-title" className="hero-title">
                JharUdyam
              </h1>
              <p className="hero-subhead">Jharkhand Civic Innovation Platform</p>
              <p className="hero-message">Report problems. Connect solutions. Create impact.</p>
              <p className="hero-desc">
                JharUdyam connects citizens with government, universities and industry to
                transform real-world societal challenges into meaningful solutions.
              </p>

              <div className="hero-actions">
                <button
                  className="l-btn l-btn-primary l-btn-lg"
                  type="button"
                  onClick={handleAppClick}
                >
                  <svg viewBox="0 0 24 24" className="l-btn-ico" aria-hidden="true">
                    <path
                      d="M12 3v12m0 0 4-4m-4 4-4-4M5 21h14"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                  Get the Citizen App
                </button>
                <button
                  className="l-btn l-btn-secondary l-btn-lg"
                  type="button"
                  onClick={handlePortalClick}
                >
                  Open Partner Portal
                  <svg viewBox="0 0 24 24" className="l-btn-ico" aria-hidden="true">
                    <path
                      d="M7 17 17 7m0 0H8m9 0v9"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                </button>
              </div>

              <div className="hero-meta">
                <span>
                  <svg viewBox="0 0 24 24" className="meta-ico" aria-hidden="true">
                    <path d="M7 2h10a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1Zm3 17h4" />
                  </svg>
                  Android app for citizens
                </span>
                <span>
                  <svg viewBox="0 0 24 24" className="meta-ico" aria-hidden="true">
                    <path d="M3 12h18M12 3a15 15 0 0 1 0 18M12 3a15 15 0 0 0 0 18M4.5 7h15M4.5 17h15" />
                  </svg>
                  Web portal for partners
                </span>
              </div>
            </div>

            <div className="hero-visual" aria-hidden="true">
              <div className="hero-emblem-glow"></div>
              <picture>
                <source srcset="/assets/logo-emblem.webp" type="image/webp" />
                <img
                  className="hero-emblem"
                  src="/assets/logo-emblem.png"
                  alt=""
                  width="520"
                  height="404"
                />
              </picture>
            </div>
          </div>
        </section>

        {/* ============================ VISION FLOW ============================ */}
        <section className="flow" aria-label="The JharUdyam journey">
          <div className="container">
            <div className="flow-band">
              <span className="flow-label">The journey</span>
              <ol className="flow-chips">
                <li>Citizen</li>
                <li>Government</li>
                <li>University&nbsp;/&nbsp;Industry</li>
                <li className="flow-chip-end">Solution</li>
              </ol>
            </div>
          </div>
        </section>

        {/* ============================ HOW IT WORKS ============================ */}
        <section className="section" id="how" aria-labelledby="how-title">
          <div className="container">
            <div className="section-head">
              <p className="eyebrow-text">How it works</p>
              <h2 id="how-title" className="section-title">
                From a single photo to a real solution
              </h2>
              <p className="section-lead">
                Four simple steps move a community problem from the street to the people who can solve
                it.
              </p>
            </div>

            <div className="steps">
              <article className="l-card step">
                <span className="step-num">01</span>
                <h3 className="step-title">Report</h3>
                <p>Citizens capture and submit a real-world problem through the mobile application.</p>
              </article>
              <article className="l-card step">
                <span className="step-num">02</span>
                <h3 className="step-title">AI Analysis</h3>
                <p>
                  AI analyzes the submitted evidence, identifies and categorizes the problem, and
                  determines the appropriate government department.
                </p>
              </article>
              <article className="l-card step">
                <span className="step-num">03</span>
                <h3 className="step-title">Government Review</h3>
                <p>
                  The government reviews submitted problems and can release suitable challenges to
                  universities or industry partners.
                </p>
              </article>
              <article className="l-card step">
                <span className="step-num">04</span>
                <h3 className="step-title">Collaborate &amp; Solve</h3>
                <p>
                  Universities and industry partners can choose relevant challenges and work toward
                  practical solutions.
                </p>
              </article>
            </div>
          </div>
        </section>

        {/* =========================== STAKEHOLDERS =========================== */}
        <section className="section section-alt" id="stakeholders" aria-labelledby="stake-title">
          <div className="container">
            <div className="section-head">
              <p className="eyebrow-text">One platform, multiple stakeholders</p>
              <h2 id="stake-title" className="section-title">
                Built for everyone who shapes change
              </h2>
              <p className="section-lead">
                A shared platform where each participant plays a distinct, meaningful role.
              </p>
            </div>

            <div className="stakeholders">
              <article className="l-card stake">
                <span className="stake-ico" data-tone="green">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M9 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm7 1a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5ZM3 20c0-3 2.7-5 6-5s6 2 6 5m2 0c0-2.2-1-3.8-2.5-4.6" />
                  </svg>
                </span>
                <h3 className="stake-title">Citizens</h3>
                <p>Report real problems from their communities with images and location.</p>
              </article>

              <article className="l-card stake">
                <span className="stake-ico" data-tone="deep">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M12 3 21 8H3l9-5Zm-6 6v7m4-7v7m4-7v7m4-7v7M4 20h16M3 17h18" />
                  </svg>
                </span>
                <h3 className="stake-title">Government</h3>
                <p>
                  Review, manage and route societal challenges and decide which problems should be
                  opened for collaboration.
                </p>
              </article>

              <article className="l-card stake">
                <span className="stake-ico" data-tone="fresh">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M12 4 2 9l10 5 8-4v6m-8-2L4 10.5" />
                  </svg>
                </span>
                <h3 className="stake-title">Universities</h3>
                <p>
                  Discover challenges released by government and contribute academic expertise,
                  students and research capabilities.
                </p>
              </article>

              <article className="l-card stake">
                <span className="stake-ico" data-tone="orange">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M4 21V9l7-4v4l7-4v16H4Zm4-3h2m4 0h2m-8-4h2m4 0h2" />
                  </svg>
                </span>
                <h3 className="stake-title">Industry</h3>
                <p>
                  Explore released challenges and contribute technology, mentorship, prototyping and
                  implementation capabilities.
                </p>
              </article>
            </div>
          </div>
        </section>

        {/* ================================ AI ================================ */}
        <section className="section" id="ai" aria-labelledby="ai-title">
          <div className="container ai-grid">
            <div className="ai-copy">
              <p className="eyebrow-text">Artificial Intelligence</p>
              <h2 id="ai-title" className="section-title">
                AI-Powered Problem Understanding
              </h2>
              <p className="section-lead">
                JharUdyam uses AI to analyze the images and information a citizen submits — turning a
                quick photo into a clear, structured, routable report.
              </p>
              <p className="ai-note">
                <svg viewBox="0 0 24 24" className="note-ico" aria-hidden="true">
                  <path d="M12 9v4m0 4h.01M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z" />
                </svg>
                AI assists — it does not decide. The government remains responsible for reviewing every
                submitted problem and choosing whether it should be released for collaboration.
              </p>
            </div>

            <div className="l-card ai-list">
              <h3 className="ai-list-title">What the AI helps with</h3>
              <ul className="checklist">
                <li>Identify the visible problem</li>
                <li>Generate a concise problem description</li>
                <li>Categorize the challenge</li>
                <li>Prioritize the challenge</li>
                <li>Detect duplicate or similar reports</li>
                <li>Determine the appropriate government department</li>
              </ul>
            </div>
          </div>
        </section>

        {/* ============================ TECHNOLOGY ============================ */}
        <section className="section section-alt" id="tech" aria-labelledby="tech-title">
          <div className="container">
            <div className="section-head">
              <p className="eyebrow-text">Technology</p>
              <h2 id="tech-title" className="section-title">
                Built for a Connected Innovation Ecosystem
              </h2>
              <p className="section-lead">
                A focused, modern stack — nothing more than the platform needs.
              </p>
            </div>

            <div className="tech">
              <article className="l-card tech-item">
                <span className="tech-ico">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M4 8V6a2 2 0 0 1 2-2h2M4 16v2a2 2 0 0 0 2 2h2m8-16h2a2 2 0 0 1 2 2v2m0 8v2a2 2 0 0 1-2 2h-2M12 9.5A2.5 2.5 0 1 0 12 14.5 2.5 2.5 0 0 0 12 9.5Z" />
                  </svg>
                </span>
                <h3>AI-powered image analysis</h3>
              </article>
              <article className="l-card tech-item">
                <span className="tech-ico">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M12 21s7-6.3 7-11a7 7 0 1 0-14 0c0 4.7 7 11 7 11Zm0-8.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z" />
                  </svg>
                </span>
                <h3>Location / GPS-based reporting</h3>
              </article>
              <article className="l-card tech-item">
                <span className="tech-ico">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M7 18a4 4 0 0 1 0-8 5.5 5.5 0 0 1 10.7-1.3A3.75 3.75 0 0 1 17.5 18H7Z" />
                  </svg>
                </span>
                <h3>Cloud-backed data platform</h3>
              </article>
              <article className="l-card tech-item">
                <span className="tech-ico">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M7 2h10a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1Zm3 17h4" />
                  </svg>
                </span>
                <h3>Citizen mobile application</h3>
              </article>
              <article className="l-card tech-item">
                <span className="tech-ico">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M3 12h18M12 3a15 15 0 0 1 0 18M12 3a15 15 0 0 0 0 18M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18Z" />
                  </svg>
                </span>
                <h3>Web-based partner portal</h3>
              </article>
            </div>
          </div>
        </section>

        {/* ============================== CTA BAND ============================== */}
        <section className="section cta-section" aria-labelledby="cta-title">
          <div className="container">
            <div className="cta-band">
              <div className="cta-text">
                <h2 id="cta-title">Ready to explore JharUdyam?</h2>
                <p>
                  Download the citizen app to report a problem, or open the partner portal to review
                  and collaborate on released challenges.
                </p>
              </div>
              <div className="cta-actions">
                <button
                  className="l-btn l-btn-on-dark"
                  type="button"
                  onClick={handleAppClick}
                >
                  Get the Citizen App
                </button>
                <button
                  className="l-btn l-btn-ghost-light"
                  type="button"
                  onClick={handlePortalClick}
                >
                  Open Partner Portal
                </button>
              </div>
            </div>
          </div>
        </section>

        {/* ============================ SIH CONTEXT ============================ */}
        <section className="section section-alt sih" id="sih" aria-labelledby="sih-title">
          <div className="container">
            <div className="section-head">
              <p className="eyebrow-text">Recognition</p>
              <h2 id="sih-title" className="section-title">
                Built for Smart India Hackathon 2026
              </h2>
            </div>
            <dl className="sih-grid">
              <div className="l-card sih-item">
                <dt>Problem Statement</dt>
                <dd>SIH26043</dd>
              </div>
              <div className="l-card sih-item">
                <dt>Theme</dt>
                <dd>Disaster Management</dd>
              </div>
              <div className="l-card sih-item">
                <dt>Organization</dt>
                <dd>Government of Jharkhand</dd>
              </div>
              <div className="l-card sih-item">
                <dt>Department</dt>
                <dd>Department of Higher &amp; Technical Education</dd>
              </div>
            </dl>
          </div>
        </section>
      </main>

      {/* ============================== FOOTER ============================== */}
      <footer className="site-footer">
        <div className="container footer-inner">
          <div className="footer-brand">
            <picture>
              <source srcset="/assets/logo-emblem.webp" type="image/webp" />
              <img
                src="/assets/logo-emblem.png"
                alt="JharUdyam emblem"
                width="52"
                height="52"
              />
            </picture>
            <div>
              <p className="footer-name">JharUdyam</p>
              <p className="footer-tag">Jharkhand Civic Innovation Platform</p>
            </div>
          </div>

          <nav className="footer-links" aria-label="Footer">
            <button className="link-btn" type="button" onClick={handleAppClick}>
              Citizen App
            </button>
            <span className="dot" aria-hidden="true">
              |
            </span>
            <Link to="/login" className="link-btn">
              Partner Portal
            </Link>
          </nav>
        </div>
        <div className="container footer-base">
          <p>Smart India Hackathon 2026 · SIH26043</p>
          <p>Report problems. Connect solutions. Create impact.</p>
        </div>
      </footer>

      {/* Toast Notification */}
      {toastMessage && (
        <div className="toast show" role="status">
          {toastMessage}
        </div>
      )}
    </div>
  )
}
