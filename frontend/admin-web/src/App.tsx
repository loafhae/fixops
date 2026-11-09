import { useCallback, useEffect, useMemo, useState } from "react";
import { api, clearToken, getToken } from "./api";
import type {
  AuditLog,
  Notification,
  Role,
  Stats,
  Ticket,
  TicketStatus,
  User,
} from "./types";

type Page = "overview" | "tickets" | "users" | "audit" | "logs";

const pageMeta: Record<Page, { title: string; subtitle: string }> = {
  overview: {
    title: "Operations overview",
    subtitle: "A live view of IT support requests and service activity.",
  },
  tickets: {
    title: "Support tickets",
    subtitle: "Review incidents and keep technology services running.",
  },
  users: {
    title: "People & access",
    subtitle: "Manage FIXOPS accounts and role-based permissions.",
  },
  audit: {
    title: "Activity log",
    subtitle: "A chronological record of important system activity.",
  },
  logs: {
    title: "System logs",
    subtitle: "Review recent FastAPI service events and operational errors.",
  },
};

function formatDate(value: string, withTime = false) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return new Intl.DateTimeFormat("en", {
    month: "short",
    day: "numeric",
    year: withTime ? "numeric" : undefined,
    hour: withTime ? "numeric" : undefined,
    minute: withTime ? "2-digit" : undefined,
  }).format(date);
}

function label(value: string) {
  return value
    .toLowerCase()
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function initials(name: string) {
  return name
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");
}

function App() {
  const [user, setUser] = useState<User | null>(null);
  const [checkingSession, setCheckingSession] = useState(true);
  const [sessionMessage, setSessionMessage] = useState("");

  useEffect(() => {
    if (!getToken()) {
      setCheckingSession(false);
      return;
    }

    api
      .me()
      .then((currentUser) => {
        if (currentUser.role === "ADMIN" || currentUser.role === "TECHNICIAN") {
          setUser(currentUser);
        } else {
          clearToken();
        }
      })
      .catch(() => {
        clearToken();
        setSessionMessage("Your session expired. Please sign in again.");
      })
      .finally(() => setCheckingSession(false));
  }, []);

  const signOut = () => {
    clearToken();
    setUser(null);
  };

  if (checkingSession) {
    return (
      <div className="boot-screen">
        <div className="brand-mark">F</div>
        <span className="spinner" />
        <p>Connecting to FIXOPS</p>
      </div>
    );
  }

  if (!user) {
    return (
      <LoginScreen
        message={sessionMessage}
        onLogin={(nextUser) => {
          setSessionMessage("");
          setUser(nextUser);
        }}
      />
    );
  }

  return <OperationsApp user={user} onSignOut={signOut} />;
}

function LoginScreen({
  message,
  onLogin,
}: {
  message: string;
  onLogin: (user: User) => void;
}) {
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(message);
  const [submitting, setSubmitting] = useState(false);

  const login = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      const currentUser = await api.login(identifier.trim(), password);
      if (currentUser.role !== "ADMIN" && currentUser.role !== "TECHNICIAN") {
        api.logout();
        throw new Error("This portal is for administrators and technicians.");
      }
      onLogin(currentUser);
    } catch (loginError) {
      setError(
        loginError instanceof Error ? loginError.message : "Unable to sign in.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  const useDemo = (role: "admin" | "tech") => {
    setIdentifier(role);
    setPassword(role);
    setError("");
  };

  return (
    <main className="login-page">
      <section className="login-aside">
        <div className="login-brand">
          <div className="brand-mark">F</div>
          <span>FIXOPS</span>
        </div>
        <div className="login-message">
          <div className="eyebrow"><span className="live-dot" /> IT SUPPORT OPERATIONS</div>
          <h1>Keep your<br />technology running.</h1>
          <p>One place to report technology issues, coordinate support, and keep your community connected.</p>
          <div className="login-note">
            <span className="note-icon">✳</span>
            <span>Built for the people who keep things running.</span>
          </div>
        </div>
        <div className="login-footer">FIXOPS OPERATIONS PORTAL <span>•</span> 2026</div>
      </section>
      <section className="login-content">
        <form className="login-card" onSubmit={login}>
          <div className="login-card-mark"><Icon name="shield" /></div>
          <div className="eyebrow">STAFF ACCESS</div>
          <h2>Welcome back</h2>
          <p className="muted">Sign in to your operations workspace.</p>

          <div className="demo-row">
            <button type="button" className="demo-chip" onClick={() => useDemo("admin")}>
              <span className="demo-dot admin-dot" /> Admin demo
            </button>
            <button type="button" className="demo-chip" onClick={() => useDemo("tech")}>
              <span className="demo-dot tech-dot" /> Technician demo
            </button>
          </div>

          <label className="field-label" htmlFor="identifier">Username or email</label>
          <input
            id="identifier"
            autoComplete="username"
            value={identifier}
            onChange={(event) => setIdentifier(event.target.value)}
            placeholder="e.g. admin@fixops.local"
            required
          />
          <label className="field-label password-label" htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            placeholder="Enter your password"
            required
          />
          {error && <div className="inline-error" role="alert">{error}</div>}
          <button className="button button-primary login-submit" disabled={submitting}>
            {submitting ? "Signing in…" : "Sign in to FIXOPS"} <span aria-hidden>→</span>
          </button>
          <div className="login-security"><Icon name="lock" /> SECURE ROLE-BASED ACCESS</div>
        </form>
      </section>
    </main>
  );
}

function OperationsApp({
  user,
  onSignOut,
}: {
  user: User;
  onSignOut: () => void;
}) {
  const isAdmin = user.role === "ADMIN";
  const [page, setPage] = useState<Page>("overview");
  const [stats, setStats] = useState<Stats | null>(null);
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [systemLogs, setSystemLogs] = useState<string[]>([]);
  const [pageBusy, setPageBusy] = useState(false);
  const [pageError, setPageError] = useState("");
  const [notice, setNotice] = useState("");
  const [apiOnline, setApiOnline] = useState<boolean | null>(null);
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [resolvingTicket, setResolvingTicket] = useState<Ticket | null>(null);
  const [editingTicketStatus, setEditingTicketStatus] = useState<Ticket | null>(null);

  const loadPage = useCallback(async () => {
    setPageBusy(true);
    setPageError("");
    try {
      if (page === "overview") {
        const healthCheck = api
          .health()
          .then((health) => setApiOnline(health.status === "healthy"))
          .catch(() => setApiOnline(false));
        const [nextStats, nextTickets] = await Promise.all([
          api.stats(),
          api.tickets(),
        ]);
        await healthCheck;
        setStats(nextStats);
        setTickets(nextTickets);
      } else if (page === "tickets") {
        setTickets(await api.tickets());
      } else if (page === "users" && isAdmin) {
        setUsers(await api.users());
      } else if (page === "audit" && isAdmin) {
        setAuditLogs(await api.auditLogs());
      } else if (page === "logs" && isAdmin) {
        setSystemLogs(await api.systemLogs());
      }
    } catch (error) {
      setPageError(error instanceof Error ? error.message : "Unable to load data.");
    } finally {
      setPageBusy(false);
    }
  }, [isAdmin, page]);

  useEffect(() => {
    void loadPage();
  }, [loadPage]);

  useEffect(() => {
    if (!notice) return;
    const timer = window.setTimeout(() => setNotice(""), 3200);
    return () => window.clearTimeout(timer);
  }, [notice]);

  const navigate = (nextPage: Page) => {
    setPageError("");
    setSelectedTicket(null);
    setPage(nextPage);
  };

  const runTicketAction = async (ticket: Ticket, action: "claim" | "start") => {
    setPageError("");
    try {
      if (action === "claim") await api.assignTicket(ticket.id, user.id);
      else await api.updateTicketStatus(ticket.id, "IN_PROGRESS");
      setNotice(action === "claim" ? "Work order claimed." : "Work started.");
      await loadPage();
    } catch (error) {
      setPageError(error instanceof Error ? error.message : "Unable to update support ticket.");
    }
  };

  const updateTicketStatus = async (
    ticket: Ticket,
    status: string,
    notes: string,
  ) => {
    setPageError("");
    try {
      await api.updateTicketStatus(ticket.id, status, notes);
      setEditingTicketStatus(null);
      setNotice("Work order status and notes updated.");
      await loadPage();
    } catch (error) {
      setPageError(error instanceof Error ? error.message : "Unable to update support ticket.");
    }
  };

  const resolveTicket = async (notes: string) => {
    if (!resolvingTicket) return;
    setPageError("");
    try {
      await api.updateTicketStatus(resolvingTicket.id, "RESOLVED", notes);
      setNotice("Work order marked as resolved.");
      setResolvingTicket(null);
      await loadPage();
      setSelectedTicket(null);
    } catch (error) {
      setPageError(error instanceof Error ? error.message : "Unable to resolve support ticket.");
    }
  };

  const saveUser = async (role: Role, isActive: boolean) => {
    if (!editingUser) return;
    setPageError("");
    try {
      await api.updateUser(editingUser.id, role, isActive);
      setEditingUser(null);
      setNotice("Account permissions updated.");
      await loadPage();
    } catch (error) {
      setPageError(error instanceof Error ? error.message : "Unable to update account.");
    }
  };

  const openTicketNotification = async (ticketId: string) => {
    setPageError("");
    try {
      const ticket = await api.ticket(ticketId);
      setPage("tickets");
      setSelectedTicket(ticket);
    } catch (error) {
      setPageError(
        error instanceof Error ? error.message : "Unable to open the support ticket.",
      );
    }
  };

  const menu: { id: Page; label: string; icon: string }[] = [
    { id: "overview", label: "Overview", icon: "grid" },
    { id: "tickets", label: "Support tickets", icon: "server" },
    ...(isAdmin
      ? [
          { id: "users" as const, label: "People & access", icon: "users" },
          { id: "audit" as const, label: "Activity log", icon: "clock" },
          { id: "logs" as const, label: "System logs", icon: "server" },
        ]
      : []),
  ];

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="brand-mark">F</div>
          <div><strong>FIXOPS</strong><small>OPERATIONS</small></div>
        </div>
        <div className="workspace-label">WORKSPACE</div>
        <nav className="side-nav" aria-label="Main navigation">
          {menu.map((item) => (
            <button
              key={item.id}
              className={`nav-item ${page === item.id ? "active" : ""}`}
              onClick={() => navigate(item.id)}
            >
              <Icon name={item.icon} />
              <span>{item.label}</span>
              {item.id === "tickets" && stats?.open_tickets ? (
                <span className="nav-count">{stats.open_tickets}</span>
              ) : null}
            </button>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="support-card">
            <span className="support-spark">✳</span>
            <strong>Everything in<br />good hands.</strong>
            <span>IT support, made clear.</span>
          </div>
          <button className="profile-button" onClick={onSignOut}>
            <span className="avatar">{initials(user.full_name)}</span>
            <span className="profile-copy">
              <strong>{user.full_name}</strong>
              <small>{label(user.role)}</small>
            </span>
            <Icon name="logout" />
          </button>
        </div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div className="breadcrumb">FIXOPS <span>/</span> {pageMeta[page].title}</div>
          <div className="topbar-right">
            <span className={`system-status ${apiOnline === false ? "system-offline" : ""}`}>
              <i />{apiOnline === null ? "Checking API" : apiOnline ? "API connected" : "API unreachable"}
            </span>
            <span className="topbar-divider" />
            <span className="topbar-date">{new Intl.DateTimeFormat("en", { weekday: "short", month: "short", day: "numeric" }).format(new Date())}</span>
            <NotificationCenter onOpenTicket={openTicketNotification} />
            <span className="avatar top-avatar">{initials(user.full_name)}</span>
          </div>
        </header>

        <section className="page-content">
          <div className="page-heading">
            <div>
              <div className="eyebrow">{isAdmin ? "ADMINISTRATOR WORKSPACE" : "TECHNICIAN WORKSPACE"}</div>
              <h1>{pageMeta[page].title}</h1>
              <p>{pageMeta[page].subtitle}</p>
            </div>
            <button className="button button-outline refresh-button" onClick={() => void loadPage()} disabled={pageBusy}>
              <Icon name="refresh" /> Refresh
            </button>
          </div>

          {pageError && (
            <div className="error-banner" role="alert">
              <span>!</span><p>{pageError}</p><button onClick={() => setPageError("")} aria-label="Dismiss error">×</button>
            </div>
          )}

          {page === "overview" && (
            <Overview
              stats={stats}
              tickets={tickets}
              busy={pageBusy}
              apiOnline={apiOnline}
              user={user}
              onOpenTicket={setSelectedTicket}
              onShowAll={() => navigate("tickets")}
            />
          )}
          {page === "tickets" && (
            <WorkOrders
              tickets={tickets}
              busy={pageBusy}
              user={user}
              onOpen={setSelectedTicket}
              onAction={runTicketAction}
              onResolve={setResolvingTicket}
            />
          )}
          {page === "users" && isAdmin && (
            <People users={users} busy={pageBusy} onEdit={setEditingUser} />
          )}
          {page === "audit" && isAdmin && (
            <ActivityLog logs={auditLogs} busy={pageBusy} />
          )}
          {page === "logs" && isAdmin && (
            <SystemLogs logs={systemLogs} busy={pageBusy} />
          )}
        </section>
      </main>

      {selectedTicket && (
        <TicketDialog
          ticket={tickets.find((item) => item.id === selectedTicket.id) ?? selectedTicket}
          user={user}
          onClose={() => setSelectedTicket(null)}
          onAction={(ticket, action) => void runTicketAction(ticket, action)}
          onResolve={setResolvingTicket}
          onEditStatus={(ticket) => setEditingTicketStatus(ticket)}
        />
      )}
      {editingUser && (
        <UserDialog
          user={editingUser}
          onClose={() => setEditingUser(null)}
          onSave={(role, active) => void saveUser(role, active)}
        />
      )}
      {resolvingTicket && (
        <ResolveDialog
          ticket={resolvingTicket}
          onClose={() => setResolvingTicket(null)}
          onResolve={(notes) => void resolveTicket(notes)}
        />
      )}
      {editingTicketStatus && (
        <StatusDialog
          ticket={editingTicketStatus}
          isAdmin={isAdmin}
          onClose={() => setEditingTicketStatus(null)}
          onSave={(status, notes) =>
            void updateTicketStatus(editingTicketStatus, status, notes)
          }
        />
      )}
      {notice && <div className="toast"><span>✓</span>{notice}</div>}
    </div>
  );
}

function Overview({
  stats,
  tickets,
  busy,
  apiOnline,
  user,
  onOpenTicket,
  onShowAll,
}: {
  stats: Stats | null;
  tickets: Ticket[];
  busy: boolean;
  apiOnline: boolean | null;
  user: User;
  onOpenTicket: (ticket: Ticket) => void;
  onShowAll: () => void;
}) {
  const critical = tickets.filter(
    (ticket) => ticket.priority === "CRITICAL" && ticket.status !== "RESOLVED",
  );
  const recent = tickets.slice(0, 5);
  const isAdmin = user.role === "ADMIN";
  const assignedTickets = tickets.filter(
    (ticket) => ticket.assigned_to_id === user.id,
  );
  const availableTickets = tickets.filter(
    (ticket) =>
      ticket.assigned_to_id === null &&
      ticket.status !== "RESOLVED" &&
      ticket.status !== "CANCELLED",
  );
  const inProgressTickets = assignedTickets.filter(
    (ticket) => ticket.status === "IN_PROGRESS",
  );
  const focusedCritical = (isAdmin ? tickets : assignedTickets).filter(
    (ticket) => ticket.priority === "CRITICAL" && ticket.status !== "RESOLVED",
  );
  const breakdownRows = (
    isAdmin
      ? Object.entries(stats?.by_priority ?? {}).sort(
          (a, b) =>
            ["CRITICAL", "HIGH", "MEDIUM", "LOW"].indexOf(a[0]) -
            ["CRITICAL", "HIGH", "MEDIUM", "LOW"].indexOf(b[0]),
        )
      : Object.entries(
          assignedTickets
            .filter(
              (ticket) =>
                !["RESOLVED", "CANCELLED"].includes(ticket.status),
            )
            .reduce<Record<string, number>>((totals, ticket) => {
              totals[ticket.category] = (totals[ticket.category] ?? 0) + 1;
              return totals;
            }, {}),
        ).sort((a, b) => b[1] - a[1])
  ).slice(0, 4);
  const maxCategory = Math.max(1, ...breakdownRows.map(([, count]) => count));

  return (
    <>
      <div className="welcome-strip">
        <div className="welcome-icon"><Icon name="spark" /></div>
        <div>
          <strong>{isAdmin ? "Your technology, in good hands." : "Ready for the next support request."}</strong>
          <span>
            {isAdmin
              ? "Here’s the latest across your technology services."
              : "Your assigned support tickets and available requests are ready below."}
          </span>
        </div>
        <div className="welcome-decoration">✳</div>
      </div>
      <div className="metric-grid">
        {isAdmin ? (
          <>
            <MetricCard title="Total reports" value={stats?.total_tickets} detail="All time" icon="ticket" accent="red" busy={busy} />
            <MetricCard title="Open support tickets" value={stats?.open_tickets} detail="Needs attention" icon="server" accent="orange" busy={busy} />
            <MetricCard title="Critical incidents" value={stats?.critical_tickets} detail="Priority response" icon="alert" accent="rose" busy={busy} />
            <MetricCard title="Resolved issues" value={stats?.resolved_tickets} detail="Successfully completed" icon="check" accent="green" busy={busy} />
          </>
        ) : (
          <>
            <MetricCard title="Assigned to me" value={assignedTickets.filter((ticket) => !["RESOLVED", "CANCELLED"].includes(ticket.status)).length} detail="Your active tickets" icon="server" accent="red" busy={busy} />
            <MetricCard title="Ready to claim" value={availableTickets.length} detail="Unassigned requests" icon="ticket" accent="orange" busy={busy} />
            <MetricCard title="In progress" value={inProgressTickets.length} detail="Currently underway" icon="refresh" accent="rose" busy={busy} />
            <MetricCard title="Urgent incidents" value={focusedCritical.length} detail="Critical priority" icon="alert" accent="green" busy={busy} />
          </>
        )}
      </div>

      {(isAdmin ? critical : focusedCritical).length > 0 && (
        <section className="critical-banner">
          <div className="critical-heading">
            <span className="critical-icon"><Icon name="alert" /></span>
            <div><strong>Priority response needed</strong><span>{(isAdmin ? critical : focusedCritical).length} critical {(isAdmin ? critical : focusedCritical).length === 1 ? "issue" : "issues"} still open</span></div>
          </div>
          <div className="critical-items">
            {(isAdmin ? critical : focusedCritical).slice(0, 3).map((ticket) => (
              <button key={ticket.id} onClick={() => onOpenTicket(ticket)}>
                <span className="critical-pulse" />
                <span className="critical-ticket-title">{ticket.title}</span>
                <span className="critical-location">{ticket.building} · {ticket.floor_room}</span>
                <span className="critical-arrow">→</span>
              </button>
            ))}
          </div>
        </section>
      )}

      <div className="overview-lower">
        <section className="panel recent-panel">
          <div className="panel-heading">
            <div><h2>Recent support tickets</h2><p>The latest technology issues reported</p></div>
            <button className="text-button" onClick={onShowAll}>All support tickets <span>→</span></button>
          </div>
          {recent.length === 0 && !busy ? (
            <EmptyState title="No reports yet" detail="New technology support requests will appear here." />
          ) : (
            <div className="recent-list">
              {recent.map((ticket) => (
                <button className="recent-item" key={ticket.id} onClick={() => onOpenTicket(ticket)}>
                  <span className={`category-icon category-${ticket.category.toLowerCase()}`}>{categorySymbol(ticket.category)}</span>
                  <span className="recent-main"><strong>{ticket.title}</strong><small>{ticket.ticket_number} <i>·</i> {ticket.building}</small></span>
                  <StatusBadge value={ticket.status} />
                  <span className="recent-date">{formatDate(ticket.created_at)}</span>
                </button>
              ))}
            </div>
          )}
        </section>
        <section className="panel category-panel">
          <div className="panel-heading"><div><h2>{isAdmin ? "Priority breakdown" : "Your work by category"}</h2><p>{isAdmin ? "Reports grouped by urgency" : "Categories in your active assignments"}</p></div><span className="panel-mini-icon">⌁</span></div>
          {breakdownRows.length === 0 ? (
            <EmptyState title="No breakdown data" detail="Work breakdowns appear as reports come in." />
          ) : (
            <div className="category-bars">
              {breakdownRows.map(([name, count], index) => (
                <div className="category-row" key={name}>
                  <div className="category-label"><span>{label(name)}</span><strong>{count}</strong></div>
                  <div className="bar-track"><span className={`bar-fill bar-${index}`} style={{ width: `${Math.max(7, (count / maxCategory) * 100)}%` }} /></div>
                </div>
              ))}
            </div>
          )}
          <div className="category-foot"><span>{isAdmin ? "All report priorities" : "Your active assignments"}</span><span className="category-dot" /></div>
        </section>
      </div>
      <section className="panel backend-panel">
        <div className="backend-icon"><Icon name="server" /></div>
        <div className="backend-copy">
          <strong>Backend API connection</strong>
          <span>Health endpoint: <code>/api/health</code></span>
        </div>
        <span className={`backend-state ${apiOnline === null ? "backend-checking" : apiOnline ? "backend-online" : "backend-offline"}`}>
          <i />{apiOnline === null ? "Checking connection" : apiOnline ? "Reachable" : "Unreachable"}
        </span>
      </section>
    </>
  );
}

function MetricCard({
  title,
  value,
  detail,
  icon,
  accent,
  busy,
}: {
  title: string;
  value: number | undefined;
  detail: string;
  icon: string;
  accent: string;
  busy: boolean;
}) {
  return (
    <article className={`metric-card metric-${accent}`}>
      <div className="metric-top"><span>{title}</span><span className="metric-icon"><Icon name={icon} /></span></div>
      <div className="metric-value">{busy && value === undefined ? "—" : (value ?? 0).toLocaleString()}</div>
      <div className="metric-detail"><span className="metric-trend">{accent === "green" ? "↗" : "•"}</span>{detail}</div>
    </article>
  );
}

function WorkOrders({
  tickets,
  busy,
  user,
  onOpen,
  onAction,
  onResolve,
}: {
  tickets: Ticket[];
  busy: boolean;
  user: User;
  onOpen: (ticket: Ticket) => void;
  onAction: (ticket: Ticket, action: "claim" | "start") => void;
  onResolve: (ticket: Ticket) => void;
}) {
  const [query, setQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [priorityFilter, setPriorityFilter] = useState("ALL");
  const [mineOnly, setMineOnly] = useState(false);
  const filtered = useMemo(() => tickets.filter((ticket) => {
    const search = query.toLowerCase().trim();
    const matchesText = !search || [
      ticket.title,
      ticket.ticket_number,
      ticket.building,
      ticket.floor_room,
      ticket.reporter?.full_name ?? "",
    ].some((value) => value.toLowerCase().includes(search));
    return (
      matchesText &&
      (statusFilter === "ALL" || ticket.status === statusFilter) &&
      (priorityFilter === "ALL" || ticket.priority === priorityFilter) &&
      (!mineOnly || ticket.assigned_to_id === user.id)
    );
  }), [mineOnly, priorityFilter, query, statusFilter, tickets, user.id]);

  const actionFor = (ticket: Ticket) => {
    if (ticket.status === "RESOLVED" || ticket.status === "CANCELLED") return null;
    if (ticket.assigned_to_id !== user.id) {
      if (ticket.assigned_to_id) return null;
      return { label: "Claim", action: "claim" as const, style: "button-soft" };
    }
    if (ticket.status !== "IN_PROGRESS") {
      return { label: "Start work", action: "start" as const, style: "button-primary button-small" };
    }
    return null;
  };

  return (
    <section className="panel table-panel">
      <div className="table-toolbar">
        <div className="table-toolbar-copy"><h2>All support tickets <span className="count-pill">{tickets.length}</span></h2><p>Search, triage, and update technology support requests.</p></div>
        <div className="table-controls">
          <label className="search-box"><Icon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search reports" /></label>
          <select aria-label="Filter by status" value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
            <option value="ALL">All statuses</option>
            {["SUBMITTED", "UNDER_REVIEW", "IN_PROGRESS", "RESOLVED", "CANCELLED"].map((item) => <option key={item} value={item}>{label(item)}</option>)}
          </select>
          <select aria-label="Filter by priority" value={priorityFilter} onChange={(event) => setPriorityFilter(event.target.value)}>
            <option value="ALL">All priorities</option>
            {["CRITICAL", "HIGH", "MEDIUM", "LOW"].map((item) => <option key={item} value={item}>{label(item)}</option>)}
          </select>
        </div>
      </div>
      <div className="work-filter-line">
        <button className={`filter-chip ${mineOnly ? "selected" : ""}`} onClick={() => setMineOnly((value) => !value)}>
          <span className="filter-check">{mineOnly ? "✓" : ""}</span> Assigned to me
        </button>
        <span className="filter-summary">{filtered.length} {filtered.length === 1 ? "result" : "results"}</span>
      </div>
      {busy && tickets.length === 0 ? <LoadingState /> : filtered.length === 0 ? (
        <EmptyState title="No matching support tickets" detail="Try changing your search or filters." />
      ) : (
        <div className="table-scroll">
          <table>
            <thead><tr><th>SUPPORT TICKET</th><th>LOCATION</th><th>REPORTED BY</th><th>PRIORITY</th><th>STATUS</th><th>ASSIGNEE</th><th className="action-heading">ACTION</th></tr></thead>
            <tbody>
              {filtered.map((ticket) => {
                const action = actionFor(ticket);
                return (
                  <tr key={ticket.id}>
                    <td><button className="work-title-button" onClick={() => onOpen(ticket)}><strong>{ticket.title}</strong><small>{ticket.ticket_number} <span>·</span> {formatDate(ticket.created_at)}</small></button></td>
                    <td><span className="cell-primary">{ticket.building}</span><small className="cell-sub">{ticket.floor_room}</small></td>
                    <td><span className="cell-primary">{ticket.reporter?.full_name ?? "Unknown"}</span><small className="cell-sub">{label(ticket.category)}</small></td>
                    <td><PriorityBadge value={ticket.priority} /></td>
                    <td><StatusBadge value={ticket.status} /></td>
                    <td><span className="assignee-cell">{ticket.technician ? <><span className="avatar tiny-avatar">{initials(ticket.technician.full_name)}</span>{ticket.technician.full_name}</> : <span className="unassigned">Unassigned</span>}</span></td>
                    <td className="action-cell">
                      {action ? (
                        <button className={`button ${action.style}`} onClick={() => onAction(ticket, action.action)}>{action.label}</button>
                      ) : ticket.assigned_to_id === user.id && ticket.status === "IN_PROGRESS" ? (
                        <button className="button button-complete" onClick={() => onResolve(ticket)}>Resolve</button>
                      ) : (
                        <button className="icon-action" aria-label="View support ticket" onClick={() => onOpen(ticket)}>↗</button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

function People({
  users,
  busy,
  onEdit,
}: {
  users: User[];
  busy: boolean;
  onEdit: (user: User) => void;
}) {
  const [query, setQuery] = useState("");
  const visibleUsers = users.filter((user) =>
    `${user.full_name} ${user.email} ${user.department} ${user.role}`
      .toLowerCase()
      .includes(query.toLowerCase().trim()),
  );

  return (
    <section className="panel table-panel">
      <div className="table-toolbar">
        <div className="table-toolbar-copy"><h2>Team directory <span className="count-pill">{users.length}</span></h2><p>Review accounts and adjust access levels.</p></div>
        <label className="search-box"><Icon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search people" /></label>
      </div>
      {busy && users.length === 0 ? <LoadingState /> : visibleUsers.length === 0 ? (
        <EmptyState title="No matching accounts" detail="Try searching by name, email, or department." />
      ) : (
        <div className="table-scroll">
          <table>
            <thead><tr><th>PERSON</th><th>DEPARTMENT</th><th>ROLE</th><th>STATUS</th><th>JOINED</th><th></th></tr></thead>
            <tbody>
              {visibleUsers.map((person) => (
                <tr key={person.id}>
                  <td><div className="person-cell"><span className={`avatar person-avatar avatar-${person.role.toLowerCase()}`}>{initials(person.full_name)}</span><span><strong>{person.full_name}</strong><small>{person.email}</small></span></div></td>
                  <td>{person.department || "General"}</td>
                  <td><RoleBadge value={person.role} /></td>
                  <td><span className={`account-status ${person.is_active ? "is-active" : "is-inactive"}`}><i />{person.is_active ? "Active" : "Inactive"}</span></td>
                  <td>{formatDate(person.created_at)}</td>
                  <td><button className="button button-outline button-small" onClick={() => onEdit(person)}>Edit access</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

function ActivityLog({ logs, busy }: { logs: AuditLog[]; busy: boolean }) {
  const [query, setQuery] = useState("");
  const filtered = logs.filter((log) =>
    `${log.action} ${log.user_email ?? ""} ${log.details ?? ""}`
      .toLowerCase()
      .includes(query.toLowerCase().trim()),
  );

  return (
    <section className="panel table-panel">
      <div className="table-toolbar">
        <div className="table-toolbar-copy"><h2>System activity <span className="count-pill">{logs.length}</span></h2><p>Recent logins, role changes, and ticket updates.</p></div>
        <label className="search-box"><Icon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search activity" /></label>
      </div>
      {busy && logs.length === 0 ? <LoadingState /> : filtered.length === 0 ? (
        <EmptyState title="No activity found" detail="System events will appear here as work happens." />
      ) : (
        <div className="table-scroll">
          <table>
            <thead><tr><th>EVENT</th><th>ACTIVITY</th><th>USER</th><th>WORK ORDER</th><th>DATE & TIME</th><th>IP ADDRESS</th></tr></thead>
            <tbody>
              {filtered.map((log) => (
                <tr key={log.id}>
                  <td><span className={`event-mark event-${eventTone(log.action)}`}>{eventGlyph(log.action)}</span></td>
                  <td><strong className="audit-action">{label(log.action)}</strong><small className="cell-sub audit-details">{log.details || "—"}</small></td>
                  <td>{log.user_email || "System"}</td>
                  <td>{log.target_ticket_id ? <code>{log.target_ticket_id.slice(0, 8)}</code> : "—"}</td>
                  <td>{formatDate(log.timestamp, true)}</td>
                  <td><code>{log.ip_address || "—"}</code></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

function SystemLogs({ logs, busy }: { logs: string[]; busy: boolean }) {
  const [query, setQuery] = useState("");
  const visibleLogs = useMemo(() => {
    const search = query.trim().toLowerCase();
    return search ? logs.filter((line) => line.toLowerCase().includes(search)) : logs;
  }, [logs, query]);

  return (
    <section className="panel system-logs-panel">
      <div className="table-toolbar">
        <div className="table-toolbar-copy">
          <h2>FastAPI service log <span className="count-pill">{logs.length}</span></h2>
          <p>Most recent server events. This view is restricted to administrators.</p>
        </div>
        <label className="search-box"><Icon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Filter log lines" /></label>
      </div>
      {busy && logs.length === 0 ? <LoadingState /> : visibleLogs.length === 0 ? (
        <EmptyState title={logs.length ? "No matching log entries" : "No system logs available"} detail={logs.length ? "Try a different search term." : "The backend log file has no entries yet."} />
      ) : (
        <ol className="system-log-list">
          {visibleLogs.map((entry, index) => (
            <li key={`${index}-${entry}`} className={entry.includes("[ERROR]") ? "log-error" : entry.includes("[WARNING]") ? "log-warning" : ""}>
              <span className="log-line-number">{index + 1}</span><code>{entry.trimEnd()}</code>
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}

function NotificationCenter({
  onOpenTicket,
}: {
  onOpenTicket: (ticketId: string) => void;
}) {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [open, setOpen] = useState(false);
  const [error, setError] = useState("");
  const unreadCount = notifications.filter((item) => !item.read_at).length;

  const refresh = useCallback(async () => {
    try {
      setNotifications(await api.notifications());
      setError("");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Unable to load notifications.",
      );
    }
  }, []);

  useEffect(() => {
    void refresh();
    const timer = window.setInterval(() => void refresh(), 30_000);
    return () => window.clearInterval(timer);
  }, [refresh]);

  const markRead = async (item: Notification) => {
    if (!item.read_at) {
      try {
        const updated = await api.markNotificationRead(item.id);
        setNotifications((current) =>
          current.map((notification) =>
            notification.id === updated.id ? updated : notification,
          ),
        );
        setError("");
      } catch (requestError) {
        setError(
          requestError instanceof Error
            ? requestError.message
            : "Unable to update notification.",
        );
        return;
      }
    }
    if (item.ticket_id) {
      setOpen(false);
      onOpenTicket(item.ticket_id);
    }
  };

  const markAllRead = async () => {
    try {
      await api.markAllNotificationsRead();
      const readAt = new Date().toISOString();
      setNotifications((current) =>
        current.map((item) => ({ ...item, read_at: item.read_at ?? readAt })),
      );
      setError("");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Unable to mark notifications as read.",
      );
    }
  };

  return (
    <div className="notification-center">
      <button
        className={`notification-trigger ${open ? "notification-trigger-open" : ""}`}
        aria-label={`Notifications${unreadCount ? `, ${unreadCount} unread` : ""}`}
        aria-expanded={open}
        onClick={() => {
          setOpen((value) => !value);
          void refresh();
        }}
      >
        <Icon name="bell" />
        {unreadCount > 0 && <span className="notification-count">{unreadCount > 99 ? "99+" : unreadCount}</span>}
      </button>
      {open && (
        <section className="notification-popover" aria-label="Notifications">
          <div className="notification-popover-heading">
            <div><strong>Notifications</strong><span>{unreadCount ? `${unreadCount} unread` : "You're all caught up"}</span></div>
            {unreadCount > 0 && <button onClick={() => void markAllRead()}>Mark all read</button>}
          </div>
          {error && <div className="notification-error" role="alert">{error}</div>}
          {notifications.length === 0 ? (
            <EmptyState title={error ? "Notifications unavailable" : "No notifications"} detail={error ? "Check your connection and try again." : "Ticket updates will appear here."} />
          ) : (
            <div className="notification-list">
              {notifications.slice(0, 12).map((item) => (
                <button className={`notification-item ${item.read_at ? "" : "notification-unread"}`} key={item.id} onClick={() => void markRead(item)}>
                  <span className={`notification-icon notification-${eventTone(item.event_type)}`}>{eventGlyph(item.event_type)}</span>
                  <span className="notification-copy"><strong>{item.message}</strong><small>{formatDate(item.created_at, true)}</small></span>
                  {!item.read_at && <i className="notification-unread-dot" />}
                </button>
              ))}
            </div>
          )}
        </section>
      )}
    </div>
  );
}

function TicketDialog({
  ticket,
  user,
  onClose,
  onAction,
  onResolve,
  onEditStatus,
}: {
  ticket: Ticket;
  user: User;
  onClose: () => void;
  onAction: (ticket: Ticket, action: "claim" | "start") => void;
  onResolve: (ticket: Ticket) => void;
  onEditStatus: (ticket: Ticket) => void;
}) {
  const isAssignedToMe = ticket.assigned_to_id === user.id;
  const isClosed = ticket.status === "RESOLVED" || ticket.status === "CANCELLED";
  const canClaim = !ticket.assigned_to_id && !isClosed;
  const canStart = isAssignedToMe && ticket.status !== "IN_PROGRESS" && !isClosed;
  const canResolve = isAssignedToMe && ticket.status === "IN_PROGRESS";

  return (
    <Modal onClose={onClose} wide>
      <div className="dialog-heading">
        <div><span className="eyebrow">{ticket.ticket_number}</span><h2>{ticket.title}</h2><p>{ticket.building} · {ticket.floor_room}</p></div>
        <button className="modal-close" onClick={onClose} aria-label="Close">×</button>
      </div>
      <div className="dialog-badges"><PriorityBadge value={ticket.priority} /><StatusBadge value={ticket.status} /><span className="category-pill">{label(ticket.category)}</span></div>
      <TicketTimeline status={ticket.status} />
      <div className="ticket-description"><div className="detail-label">ISSUE DESCRIPTION</div><p>{ticket.description}</p></div>
      <div className="ticket-detail-grid">
        <div><span className="detail-label">REPORTED BY</span><strong>{ticket.reporter?.full_name ?? "Unknown"}</strong><small>{ticket.reporter?.email ?? ""}</small></div>
        <div><span className="detail-label">ASSIGNED TO</span><strong>{ticket.technician?.full_name ?? "Unassigned"}</strong><small>{ticket.technician?.email ?? ""}</small></div>
        <div><span className="detail-label">REPORTED</span><strong>{formatDate(ticket.created_at, true)}</strong></div>
        <div><span className="detail-label">LAST UPDATED</span><strong>{formatDate(ticket.updated_at, true)}</strong></div>
      </div>
      {ticket.attachments.length > 0 && (
        <div className="attachment-section">
          <span className="detail-label">PHOTO EVIDENCE & ATTACHMENTS ({ticket.attachments.length})</span>
          <div className="attachment-grid">
            {ticket.attachments.map((file) => (
              <a className="attachment-preview" key={file.id} href={api.attachmentUrl(file.file_path)} target="_blank" rel="noreferrer">
                <img
                  src={api.attachmentUrl(file.file_path)}
                  alt={file.file_name}
                  loading="lazy"
                  onError={(event) => {
                    event.currentTarget.hidden = true;
                    event.currentTarget.parentElement?.classList.add("attachment-unavailable");
                  }}
                />
                <span><span>↗</span>{file.file_name}</span>
              </a>
            ))}
          </div>
        </div>
      )}
      {ticket.resolution_notes && <div className="resolution-note"><span className="detail-label">RESOLUTION NOTES</span><p>{ticket.resolution_notes}</p></div>}
      <div className="dialog-actions">
        {(user.role === "ADMIN" || (isAssignedToMe && !isClosed)) && (
          <button className="button button-outline status-edit-button" onClick={() => onEditStatus(ticket)}>
            Update status & notes
          </button>
        )}
        {canClaim && <button className="button button-soft" onClick={() => onAction(ticket, "claim")}>Claim ticket</button>}
        {canStart && <button className="button button-primary" onClick={() => onAction(ticket, "start")}>Start work <span>→</span></button>}
        {canResolve && <button className="button button-complete" onClick={() => onResolve(ticket)}>Mark resolved <span>✓</span></button>}
        <button className="button button-outline" onClick={onClose}>Close</button>
      </div>
    </Modal>
  );
}

function TicketTimeline({ status }: { status: string }) {
  const steps = ["SUBMITTED", "UNDER_REVIEW", "IN_PROGRESS", "RESOLVED"];
  const currentIndex = steps.indexOf(status);

  return (
    <div className="ticket-timeline">
      <span className="detail-label">LIFECYCLE PROGRESSION</span>
      <div className="timeline-steps">
        {steps.map((step, index) => {
          const complete = currentIndex > index;
          const current = currentIndex === index;
          return (
            <div className="timeline-step-wrap" key={step}>
              <div className="timeline-step">
                <span className={`timeline-marker ${complete ? "complete" : ""} ${current ? "current" : ""}`}>
                  {complete ? "✓" : current ? "•" : ""}
                </span>
                <span className={current ? "timeline-current-label" : ""}>{label(step)}</span>
              </div>
              {index < steps.length - 1 && <span className={`timeline-connector ${complete ? "complete" : ""}`} />}
            </div>
          );
        })}
      </div>
      {status === "CANCELLED" && <div className="cancelled-note"><i /> This support ticket was cancelled.</div>}
    </div>
  );
}

function UserDialog({
  user,
  onClose,
  onSave,
}: {
  user: User;
  onClose: () => void;
  onSave: (role: Role, isActive: boolean) => void;
}) {
  const [role, setRole] = useState<Role>(user.role);
  const [active, setActive] = useState(user.is_active);

  return (
    <Modal onClose={onClose}>
      <div className="dialog-heading">
        <div><span className="eyebrow">ACCOUNT PERMISSIONS</span><h2>Edit access</h2><p>{user.full_name} · {user.email}</p></div>
        <button className="modal-close" onClick={onClose} aria-label="Close">×</button>
      </div>
      <label className="field-label" htmlFor="role-select">Assigned role</label>
      <select id="role-select" className="dialog-select" value={role} onChange={(event) => setRole(event.target.value as Role)}>
        <option value="USER">User</option><option value="TECHNICIAN">Technician</option><option value="ADMIN">Admin</option>
      </select>
      <button className={`account-toggle ${active ? "toggle-on" : ""}`} onClick={() => setActive((value) => !value)} type="button">
        <span className="toggle-switch"><i /></span><span><strong>Account active</strong><small>{active ? "This person can sign in to FIXOPS." : "Sign-in access is disabled."}</small></span>
      </button>
      <div className="dialog-actions">
        <button className="button button-outline" onClick={onClose}>Cancel</button>
        <button className="button button-primary" onClick={() => onSave(role, active)}>Save changes <span>→</span></button>
      </div>
    </Modal>
  );
}

function StatusDialog({
  ticket,
  isAdmin,
  onClose,
  onSave,
}: {
  ticket: Ticket;
  isAdmin: boolean;
  onClose: () => void;
  onSave: (status: TicketStatus, notes: string) => void;
}) {
  const [status, setStatus] = useState<TicketStatus>(ticket.status);
  const [notes, setNotes] = useState(ticket.resolution_notes ?? "");
  const statuses: TicketStatus[] = isAdmin
    ? ["SUBMITTED", "UNDER_REVIEW", "IN_PROGRESS", "RESOLVED", "CANCELLED"]
    : ["IN_PROGRESS", "RESOLVED"];

  return (
    <Modal onClose={onClose}>
      <div className="dialog-heading">
        <div><span className="eyebrow">WORK ORDER UPDATE</span><h2>Update status & notes</h2><p>{ticket.ticket_number} · {ticket.title}</p></div>
        <button className="modal-close" onClick={onClose} aria-label="Close">×</button>
      </div>
      <label className="field-label" htmlFor="ticket-status">New status</label>
      <select id="ticket-status" className="dialog-select" value={status} onChange={(event) => setStatus(event.target.value as TicketStatus)}>
        {statuses.map((item) => <option key={item} value={item}>{label(item)}</option>)}
      </select>
      <label className="field-label" htmlFor="work-log">Resolution notes / work log</label>
      <textarea id="work-log" className="resolution-input" rows={4} value={notes} onChange={(event) => setNotes(event.target.value)} placeholder="Describe the work completed, next steps, or parts required…" />
      <div className="dialog-actions">
        <button className="button button-outline" onClick={onClose}>Cancel</button>
        <button className="button button-primary" onClick={() => onSave(status, notes.trim())}>Save update <span>→</span></button>
      </div>
    </Modal>
  );
}

function ResolveDialog({
  ticket,
  onClose,
  onResolve,
}: {
  ticket: Ticket;
  onClose: () => void;
  onResolve: (notes: string) => void;
}) {
  const [notes, setNotes] = useState("");
  return (
    <Modal onClose={onClose}>
      <div className="dialog-heading">
        <div><span className="eyebrow">COMPLETE WORK ORDER</span><h2>Mark as resolved</h2><p>{ticket.ticket_number} · {ticket.title}</p></div>
        <button className="modal-close" onClick={onClose} aria-label="Close">×</button>
      </div>
      <label className="field-label" htmlFor="resolution-notes">Resolution notes <span className="optional">(optional)</span></label>
      <textarea id="resolution-notes" className="resolution-input" rows={4} value={notes} onChange={(event) => setNotes(event.target.value)} placeholder="Describe the troubleshooting or resolution steps…" />
      <div className="dialog-actions">
        <button className="button button-outline" onClick={onClose}>Cancel</button>
        <button className="button button-complete" onClick={() => onResolve(notes.trim())}>Confirm resolution <span>✓</span></button>
      </div>
    </Modal>
  );
}

function Modal({
  children,
  onClose,
  wide = false,
}: {
  children: React.ReactNode;
  onClose: () => void;
  wide?: boolean;
}) {
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [onClose]);

  return (
    <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <section className={`modal-card ${wide ? "modal-wide" : ""}`} role="dialog" aria-modal="true">
        {children}
      </section>
    </div>
  );
}

function StatusBadge({ value }: { value: string }) {
  return <span className={`status-badge status-${value.toLowerCase()}`}><i />{label(value)}</span>;
}

function PriorityBadge({ value }: { value: string }) {
  return <span className={`priority-badge priority-${value.toLowerCase()}`}><i />{label(value)}</span>;
}

function RoleBadge({ value }: { value: string }) {
  return <span className={`role-badge role-${value.toLowerCase()}`}>{label(value)}</span>;
}

function EmptyState({ title, detail }: { title: string; detail: string }) {
  return <div className="empty-state"><span className="empty-icon">⌁</span><strong>{title}</strong><p>{detail}</p></div>;
}

function LoadingState() {
  return <div className="loading-state"><span className="spinner" /> Loading records…</div>;
}

function Icon({ name }: { name: string }) {
  const paths: Record<string, React.ReactNode> = {
    grid: <><rect x="3" y="3" width="7" height="7" rx="1.5" /><rect x="14" y="3" width="7" height="7" rx="1.5" /><rect x="14" y="14" width="7" height="7" rx="1.5" /><rect x="3" y="14" width="7" height="7" rx="1.5" /></>,
    wrench: <><path d="M14.7 6.3a5 5 0 0 0-6.4 6.4L3 18l3 3 5.3-5.3a5 5 0 0 0 6.4-6.4L14 12l-2-2 2.7-3.7Z" /><path d="m18 3 3 3-3.5 3.5-3-3L18 3Z" /></>,
    users: <><path d="M16 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="10" cy="7" r="4" /><path d="M20 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8" /></>,
    clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
    bell: <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" /><path d="M10 21h4" /></>,
    ticket: <><path d="M3 8V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v3a3 3 0 0 0 0 6v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-3a3 3 0 0 0 0-6Z" /><path d="M13 5v2m0 4v2m0 4v2" /></>,
    alert: <><path d="m10.3 3.9-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.7-3.1l-8-14a2 2 0 0 0-3.4 0Z" /><path d="M12 9v4m0 4h.01" /></>,
    check: <><path d="M20 6 9 17l-5-5" /><circle cx="12" cy="12" r="10" /></>,
    search: <><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></>,
    refresh: <><path d="M20 7v5h-5M4 17v-5h5" /><path d="M5.5 9a7 7 0 0 1 11.6-2L20 12M4 12l2.9 5a7 7 0 0 0 11.6-2" /></>,
    logout: <><path d="M10 17l5-5-5-5m5 5H3" /><path d="M12 3h6a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-6" /></>,
    shield: <><path d="M12 22s8-4 8-11V5l-8-3-8 3v6c0 7 8 11 8 11Z" /><path d="m9 12 2 2 4-4" /></>,
    lock: <><rect x="4" y="10" width="16" height="11" rx="2" /><path d="M8 10V7a4 4 0 1 1 8 0v3" /></>,
    server: <><rect x="3" y="4" width="18" height="7" rx="2" /><rect x="3" y="13" width="18" height="7" rx="2" /><path d="M7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6" /></>,
    spark: <><path d="m12 3 1.9 5.8L20 11l-6.1 2.2L12 19l-1.9-5.8L4 11l6.1-2.2L12 3Z" /><path d="m19 14 1.2 2.8L23 18l-2.8 1.2L19 22l-1.2-2.8L15 18l2.8-1.2L19 14Z" /></>,
  };
  return <svg className="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name] ?? paths.grid}</svg>;
}

function categorySymbol(category: string) {
  const symbols: Record<string, string> = {
    HARDWARE: "▣",
    SOFTWARE: "⌘",
    NETWORK: "⌁",
    ACCOUNT_ACCESS: "♙",
    CYBERSECURITY: "⛨",
    OTHER: "✧",
  };
  return symbols[category.toUpperCase()] ?? "✧";
}

function eventTone(action: string) {
  if (action.includes("LOGIN") || action.includes("AUTH") || action.includes("UPDATED")) return "blue";
  if (action.includes("RESOLVED") || action.includes("STATUS")) return "green";
  if (action.includes("ROLE") || action.includes("ASSIGNED")) return "purple";
  if (action.includes("CREATED") || action.includes("SUBMITTED")) return "orange";
  return "neutral";
}

function eventGlyph(action: string) {
  if (action.includes("LOGIN") || action.includes("AUTH")) return "↗";
  if (action.includes("RESOLVED") || action.includes("STATUS")) return "✓";
  if (action.includes("ROLE") || action.includes("ASSIGNED")) return "♙";
  if (action.includes("CREATED") || action.includes("SUBMITTED")) return "+";
  return "•";
}

export default App;
