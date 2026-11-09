export type Role = "ADMIN" | "TECHNICIAN" | "USER";
export type TicketStatus =
  | "SUBMITTED"
  | "UNDER_REVIEW"
  | "IN_PROGRESS"
  | "RESOLVED"
  | "CANCELLED";
export type TicketPriority = "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";

export interface User {
  id: string;
  email: string;
  full_name: string;
  role: Role;
  department: string;
  is_active: boolean;
  created_at: string;
}

export interface Attachment {
  id: string;
  file_path: string;
  file_name: string;
  file_type: string;
}

export interface Ticket {
  id: string;
  ticket_number: string;
  title: string;
  description: string;
  building: string;
  floor_room: string;
  category: string;
  priority: TicketPriority;
  status: TicketStatus;
  reported_by_id: string;
  assigned_to_id: string | null;
  resolution_notes: string | null;
  created_at: string;
  updated_at: string;
  reporter: User | null;
  technician: User | null;
  attachments: Attachment[];
}

export interface Stats {
  total_tickets: number;
  open_tickets: number;
  resolved_tickets: number;
  critical_tickets: number;
  by_category: Record<string, number>;
  by_priority: Record<string, number>;
  by_status: Record<string, number>;
}

export interface AuditLog {
  id: string;
  user_id: string | null;
  user_email: string | null;
  action: string;
  target_ticket_id: string | null;
  details: string | null;
  ip_address: string | null;
  timestamp: string;
}

export interface Notification {
  id: string;
  ticket_id: string | null;
  event_type: string;
  message: string;
  created_at: string;
  read_at: string | null;
}
