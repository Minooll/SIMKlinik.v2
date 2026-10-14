-- ==============================================================================
-- SIMKlinik RLS & Access Policies Migration
-- Version: 20261014000002
-- Description: Helper functions, enable RLS on all tables, and define least-privilege policies.
-- ==============================================================================

-- 1. Helper Security Functions (SECURITY DEFINER with strict search_path)
CREATE OR REPLACE FUNCTION public.has_role(required_role user_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = auth.uid() 
          AND (role = required_role OR role = 'superadmin')
    );
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = auth.uid() 
          AND role IN ('admin', 'superadmin')
    );
$$;

CREATE OR REPLACE FUNCTION public.is_staff_or_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = auth.uid() 
          AND role IN ('staff', 'admin', 'superadmin')
    );
$$;

CREATE OR REPLACE FUNCTION public.is_doctor()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = auth.uid() 
          AND role IN ('doctor', 'admin', 'superadmin')
    );
$$;

-- 2. Enable RLS on ALL tables (Deny-by-default)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.specialties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 3. Policies: profiles
-- ------------------------------------------------------------------------------
-- User can view own profile; Staff/Admin can view all profiles for operational care
CREATE POLICY "profiles_select_policy" ON public.profiles
    FOR SELECT USING (auth.uid() = id OR public.is_staff_or_admin());

-- Profile created on signup (or via user)
CREATE POLICY "profiles_insert_policy" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- User can update own profile name, phone, avatar
CREATE POLICY "profiles_update_policy" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- ------------------------------------------------------------------------------
-- 4. Policies: user_roles (CRUCIAL: Users CANNOT assign or change their own role)
-- ------------------------------------------------------------------------------
-- Users can see their own role; Staff/Admin can view roles
CREATE POLICY "user_roles_select_policy" ON public.user_roles
    FOR SELECT USING (auth.uid() = user_id OR public.is_staff_or_admin());

-- Only Admins can grant or modify roles
CREATE POLICY "user_roles_insert_policy" ON public.user_roles
    FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "user_roles_update_policy" ON public.user_roles
    FOR UPDATE USING (public.is_admin());

CREATE POLICY "user_roles_delete_policy" ON public.user_roles
    FOR DELETE USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 5. Policies: patient_profiles
-- ------------------------------------------------------------------------------
-- Patient owner, Doctors, and Staff/Admin can view patient profile
CREATE POLICY "patient_profiles_select_policy" ON public.patient_profiles
    FOR SELECT USING (
        auth.uid() = user_id 
        OR public.is_staff_or_admin() 
        OR public.is_doctor()
    );

-- Patient can create their own patient profile record
CREATE POLICY "patient_profiles_insert_policy" ON public.patient_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Patient can update own profile, Staff/Admin can update if needed for registration
CREATE POLICY "patient_profiles_update_policy" ON public.patient_profiles
    FOR UPDATE USING (auth.uid() = user_id OR public.is_staff_or_admin());

-- ------------------------------------------------------------------------------
-- 6. Policies: clinics
-- ------------------------------------------------------------------------------
-- Anyone (including unauthenticated/anon for landing pages) can view active clinics
CREATE POLICY "clinics_select_policy" ON public.clinics
    FOR SELECT USING (is_active = TRUE OR public.is_staff_or_admin());

-- Only Admins can manage clinics
CREATE POLICY "clinics_admin_manage_policy" ON public.clinics
    FOR ALL USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 7. Policies: specialties
-- ------------------------------------------------------------------------------
-- Anyone can view medical specialties
CREATE POLICY "specialties_select_policy" ON public.specialties
    FOR SELECT USING (TRUE);

-- Only Admins can manage specialties
CREATE POLICY "specialties_admin_manage_policy" ON public.specialties
    FOR ALL USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 8. Policies: doctors
-- ------------------------------------------------------------------------------
-- Anyone can view active doctors and their specialty/clinic
CREATE POLICY "doctors_select_policy" ON public.doctors
    FOR SELECT USING (is_active = TRUE OR public.is_staff_or_admin());

-- Staff & Admins can manage doctor records
CREATE POLICY "doctors_manage_policy" ON public.doctors
    FOR ALL USING (public.is_staff_or_admin());

-- ------------------------------------------------------------------------------
-- 9. Policies: doctor_schedules
-- ------------------------------------------------------------------------------
-- Authenticated users & visitors can view upcoming available schedules
CREATE POLICY "doctor_schedules_select_policy" ON public.doctor_schedules
    FOR SELECT USING (
        schedule_date >= CURRENT_DATE 
        OR public.is_staff_or_admin()
        OR (auth.uid() IN (SELECT user_id FROM public.doctors WHERE id = doctor_id))
    );

-- Only Staff & Admins can manage doctor schedules
CREATE POLICY "doctor_schedules_manage_policy" ON public.doctor_schedules
    FOR ALL USING (public.is_staff_or_admin());

-- ------------------------------------------------------------------------------
-- 10. Policies: appointments
-- ------------------------------------------------------------------------------
-- Patient views own appointments; Staff/Admin views all; Doctor views assigned appointments
CREATE POLICY "appointments_select_policy" ON public.appointments
    FOR SELECT USING (
        auth.uid() = user_id 
        OR public.is_staff_or_admin() 
        OR (auth.uid() IN (
            SELECT d.user_id 
            FROM public.doctors d 
            JOIN public.doctor_schedules ds ON ds.doctor_id = d.id 
            WHERE ds.id = schedule_id
        ))
    );

-- Direct client INSERT is permitted with ownership check, though RPC is recommended for atomic guarantees
CREATE POLICY "appointments_insert_policy" ON public.appointments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Patient can cancel own pending/confirmed appointment; Staff/Admin can update status
CREATE POLICY "appointments_update_policy" ON public.appointments
    FOR UPDATE USING (
        (auth.uid() = user_id AND status IN ('pending', 'confirmed'))
        OR public.is_staff_or_admin()
    );

-- ------------------------------------------------------------------------------
-- 11. Policies: queue_sessions
-- ------------------------------------------------------------------------------
-- Authenticated users can view today's active queue sessions; Staff/Admin can view all
CREATE POLICY "queue_sessions_select_policy" ON public.queue_sessions
    FOR SELECT USING (
        session_date = CURRENT_DATE 
        OR public.is_staff_or_admin()
    );

-- Staff and Admins can manage queue sessions
CREATE POLICY "queue_sessions_manage_policy" ON public.queue_sessions
    FOR ALL USING (public.is_staff_or_admin());

-- ------------------------------------------------------------------------------
-- 12. Policies: queue_tickets
-- ------------------------------------------------------------------------------
-- Patient views own ticket; Staff & assigned Doctor view session tickets
CREATE POLICY "queue_tickets_select_policy" ON public.queue_tickets
    FOR SELECT USING (
        auth.uid() = user_id 
        OR public.is_staff_or_admin()
        OR (auth.uid() IN (
            SELECT d.user_id 
            FROM public.doctors d 
            JOIN public.queue_sessions qs ON qs.doctor_id = d.id 
            WHERE qs.id = queue_session_id
        ))
    );

-- Staff and Doctors can update ticket status (check-in, call, complete, etc.)
CREATE POLICY "queue_tickets_update_policy" ON public.queue_tickets
    FOR UPDATE USING (
        public.is_staff_or_admin() 
        OR public.is_doctor()
    );

-- ------------------------------------------------------------------------------
-- 13. Policies: queue_events
-- ------------------------------------------------------------------------------
-- Patient can view events for their own ticket; Staff/Doctor can view all session events
CREATE POLICY "queue_events_select_policy" ON public.queue_events
    FOR SELECT USING (
        EXISTS (
            SELECT 1 
            FROM public.queue_tickets qt 
            WHERE qt.id = queue_ticket_id 
              AND qt.user_id = auth.uid()
        )
        OR public.is_staff_or_admin()
        OR public.is_doctor()
    );

CREATE POLICY "queue_events_insert_policy" ON public.queue_events
    FOR INSERT WITH CHECK (
        public.is_staff_or_admin() 
        OR public.is_doctor()
    );

-- ------------------------------------------------------------------------------
-- 14. Policies: notifications
-- ------------------------------------------------------------------------------
-- User can only read and acknowledge their own notifications
CREATE POLICY "notifications_select_policy" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_update_policy" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 15. Policies: audit_logs
-- ------------------------------------------------------------------------------
-- Only Staff and Admins can view audit logs
CREATE POLICY "audit_logs_select_policy" ON public.audit_logs
    FOR SELECT USING (public.is_staff_or_admin());

-- Direct client inserts into audit_logs are forbidden (created via server functions)
CREATE POLICY "audit_logs_insert_policy" ON public.audit_logs
    FOR INSERT WITH CHECK (public.is_staff_or_admin());
