import type {
  AuditLog,
  Notification,
  Role,
  Stats,
  Ticket,
  User,
} from "./types";

const API_URL = (
  import.meta.env.VITE_API_URL ?? "http://127.0.0.1:8000/api/v1"
).replace(/\/$/, "");
const API_ROOT = API_URL.replace(/\/api\/v1$/, "");
const TOKEN_KEY = "fixops_admin_token";

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers);
  const token = getToken();
  if (token) headers.set("Authorization", `Bearer ${token}`);
  if (init.body && !(init.body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }

  const url = /^https?:\/\//i.test(path) ? path : `${API_URL}${path}`;
  const response = await fetch(url, { ...init, headers });
  if (!response.ok) {
    let message = `Request failed (${response.status})`;
    try {
      const body = await response.json();
      if (typeof body.detail === "string") message = body.detail;
    } catch {
      // The response may not contain JSON.
    }
    throw new Error(message);
  }
  if (response.status === 204) return undefined as T;
  return response.json() as Promise<T>;
}

export const api = {
  async login(identifier: string, password: string) {
    const result = await request<{ access_token: string; user: User }>(
      "/auth/login",
      {
        method: "POST",
        body: JSON.stringify({ email: identifier, password }),
      },
    );
    localStorage.setItem(TOKEN_KEY, result.access_token);
    return result.user;
  },
  me: () => request<User>("/auth/me"),
  logout: clearToken,
  health: () => request<{ status: string }>(`${API_ROOT}/api/health`),
  stats: () => request<Stats>("/stats/"),
  tickets: () => request<Ticket[]>("/tickets/"),
  ticket: (id: string) => request<Ticket>(`/tickets/${id}`),
  updateTicketStatus: (id: string, status: string, resolutionNotes?: string) =>
    request<Ticket>(`/tickets/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({
        status,
        ...(resolutionNotes ? { resolution_notes: resolutionNotes } : {}),
      }),
    }),
  assignTicket: (id: string, technicianId: string) =>
    request<Ticket>(`/tickets/${id}/assign`, {
      method: "PATCH",
      body: JSON.stringify({ technician_id: technicianId }),
    }),
  users: () => request<User[]>("/users/"),
  updateUser: (id: string, role: Role, isActive: boolean) =>
    request<User>(`/users/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ role, is_active: isActive }),
    }),
  auditLogs: () => request<AuditLog[]>("/audit-logs/?limit=100"),
  systemLogs: () => request<string[]>("/system/logs?limit=200"),
  notifications: () => request<Notification[]>("/notifications/?limit=30"),
  markNotificationRead: (id: string) =>
    request<Notification>(`/notifications/${id}/read`, { method: "PATCH" }),
  markAllNotificationsRead: () =>
    request<void>("/notifications/read-all", { method: "POST" }),
  attachmentUrl: (path: string) => `${API_ROOT}${path}`,
};
