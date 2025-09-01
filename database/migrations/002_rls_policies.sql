-- Migration: 002_rls_policies
-- Description: Row Level Security (RLS) policies for deegongso platform
-- Created: 2025-08-29

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sanctions ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT role = 'admin'
    FROM users
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is super admin
CREATE OR REPLACE FUNCTION auth.is_super_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT role = 'admin' AND admin_level = 'super'
    FROM users
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is project participant
CREATE OR REPLACE FUNCTION auth.is_project_participant(project_uuid UUID)
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT EXISTS (
      SELECT 1 FROM projects
      WHERE id = project_uuid
      AND (client_id = auth.uid() OR designer_id = auth.uid())
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- USERS TABLE POLICIES
-- =====================================================

-- Users can view their own profile and public profiles
CREATE POLICY "Users can view profiles" ON users
  FOR SELECT USING (
    id = auth.uid() OR -- own profile
    auth.is_admin() OR -- admin can view all
    role != 'admin' -- non-admin profiles are public (designers, clients)
  );

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Admin can update any user (for verification, sanctions, etc.)
CREATE POLICY "Admins can manage users" ON users
  FOR ALL USING (auth.is_admin());

-- New users can insert their profile after auth signup
CREATE POLICY "Users can create profile" ON users
  FOR INSERT WITH CHECK (id = auth.uid());

-- =====================================================
-- PROJECTS TABLE POLICIES  
-- =====================================================

-- Anyone can view active projects (for marketplace)
CREATE POLICY "Anyone can view active projects" ON projects
  FOR SELECT USING (
    status IN ('creation_pending', 'review_requested') OR -- public projects
    client_id = auth.uid() OR -- client can see their projects
    designer_id = auth.uid() OR -- assigned designer can see
    auth.is_admin() -- admin can see all
  );

-- Only clients can create projects
CREATE POLICY "Clients can create projects" ON projects
  FOR INSERT WITH CHECK (
    client_id = auth.uid() AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'client')
  );

-- Project participants can update projects
CREATE POLICY "Project participants can update" ON projects
  FOR UPDATE USING (
    client_id = auth.uid() OR
    designer_id = auth.uid() OR
    auth.is_admin()
  );

-- =====================================================
-- PROPOSALS TABLE POLICIES
-- =====================================================

-- Project client and proposal designer can view proposals
CREATE POLICY "View proposals" ON proposals
  FOR SELECT USING (
    designer_id = auth.uid() OR -- designer can see their proposals
    EXISTS (SELECT 1 FROM projects WHERE id = project_id AND client_id = auth.uid()) OR -- client can see proposals for their project
    auth.is_admin()
  );

-- Only designers can create proposals
CREATE POLICY "Designers can create proposals" ON proposals
  FOR INSERT WITH CHECK (
    designer_id = auth.uid() AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'designer')
  );

-- Designer can update their own proposals, client can update status
CREATE POLICY "Update proposals" ON proposals
  FOR UPDATE USING (
    designer_id = auth.uid() OR -- designer can update their proposal
    (EXISTS (SELECT 1 FROM projects WHERE id = project_id AND client_id = auth.uid())) OR -- client can accept/reject
    auth.is_admin()
  );

-- =====================================================
-- PROJECT FILES POLICIES
-- =====================================================

-- Project participants can view files
CREATE POLICY "View project files" ON project_files
  FOR SELECT USING (
    auth.is_project_participant(project_id) OR
    auth.is_admin()
  );

-- Project participants can upload files
CREATE POLICY "Upload project files" ON project_files
  FOR INSERT WITH CHECK (
    uploaded_by = auth.uid() AND
    auth.is_project_participant(project_id)
  );

-- File uploader and project client can delete files
CREATE POLICY "Delete project files" ON project_files
  FOR DELETE USING (
    uploaded_by = auth.uid() OR
    EXISTS (SELECT 1 FROM projects WHERE id = project_id AND client_id = auth.uid()) OR
    auth.is_admin()
  );

-- =====================================================
-- FEEDBACK TABLE POLICIES
-- =====================================================

-- Project participants can view feedback
CREATE POLICY "View feedback" ON feedback
  FOR SELECT USING (
    auth.is_project_participant(project_id) OR
    auth.is_admin()
  );

-- Project participants can create feedback
CREATE POLICY "Create feedback" ON feedback
  FOR INSERT WITH CHECK (
    created_by = auth.uid() AND
    auth.is_project_participant(project_id)
  );

-- Feedback creator can update their feedback
CREATE POLICY "Update feedback" ON feedback
  FOR UPDATE USING (
    created_by = auth.uid() OR
    auth.is_admin()
  );

-- =====================================================
-- FEEDBACK COMMENTS POLICIES
-- =====================================================

-- Users can view comments on feedback they can access
CREATE POLICY "View feedback comments" ON feedback_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM feedback 
      WHERE id = feedback_id 
      AND (auth.is_project_participant(project_id) OR auth.is_admin())
    )
  );

-- Users can create comments on accessible feedback
CREATE POLICY "Create feedback comments" ON feedback_comments
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM feedback 
      WHERE id = feedback_id 
      AND auth.is_project_participant(project_id)
    )
  );

-- Comment creator can update their own comments
CREATE POLICY "Update feedback comments" ON feedback_comments
  FOR UPDATE USING (
    user_id = auth.uid() OR
    auth.is_admin()
  );

-- =====================================================
-- PAYMENTS TABLE POLICIES
-- =====================================================

-- Payment participants can view payment info
CREATE POLICY "View payments" ON payments
  FOR SELECT USING (
    client_id = auth.uid() OR
    designer_id = auth.uid() OR
    auth.is_admin()
  );

-- Only clients can initiate payments
CREATE POLICY "Create payments" ON payments
  FOR INSERT WITH CHECK (
    client_id = auth.uid() AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'client')
  );

-- Payment processing updates (by system/admin)
CREATE POLICY "Update payments" ON payments
  FOR UPDATE USING (auth.is_admin());

-- =====================================================
-- NOTIFICATIONS TABLE POLICIES
-- =====================================================

-- Users can only see their own notifications
CREATE POLICY "View own notifications" ON notifications
  FOR SELECT USING (
    user_id = auth.uid() OR
    auth.is_admin()
  );

-- System/admin can create notifications
CREATE POLICY "Create notifications" ON notifications
  FOR INSERT WITH CHECK (auth.is_admin());

-- Users can mark their notifications as read
CREATE POLICY "Update own notifications" ON notifications
  FOR UPDATE USING (
    user_id = auth.uid() OR
    auth.is_admin()
  );

-- Users can delete their own notifications
CREATE POLICY "Delete own notifications" ON notifications
  FOR DELETE USING (
    user_id = auth.uid() OR
    auth.is_admin()
  );

-- =====================================================
-- ADMIN TABLES POLICIES
-- =====================================================

-- Only admins can access disputes
CREATE POLICY "Admins manage disputes" ON disputes
  FOR ALL USING (
    auth.is_admin() OR
    created_by = auth.uid() -- dispute creator can view
  );

-- Only super admins can manage user sanctions
CREATE POLICY "Super admins manage sanctions" ON user_sanctions
  FOR ALL USING (auth.is_super_admin());

-- Only admins can access admin logs
CREATE POLICY "Admins access logs" ON admin_logs
  FOR SELECT USING (auth.is_admin());

CREATE POLICY "Admins create logs" ON admin_logs
  FOR INSERT WITH CHECK (
    admin_id = auth.uid() AND
    auth.is_admin()
  );

-- Announcements policies
CREATE POLICY "Anyone can view published announcements" ON announcements
  FOR SELECT USING (
    status = 'published' OR
    auth.is_admin()
  );

CREATE POLICY "Admins manage announcements" ON announcements
  FOR ALL USING (auth.is_admin());

-- Announcement reads policies
CREATE POLICY "Users can track announcement reads" ON announcement_reads
  FOR SELECT USING (
    user_id = auth.uid() OR
    auth.is_admin()
  );

CREATE POLICY "Users can mark announcements as read" ON announcement_reads
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Update announcement reads" ON announcement_reads
  FOR UPDATE USING (
    user_id = auth.uid() OR
    auth.is_admin()
  );

-- =====================================================
-- FUNCTIONS FOR APPLICATION LOGIC
-- =====================================================

-- Function to auto-create user profile from auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'client')::user_role
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create user profile
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to send notification when new feedback is created
CREATE OR REPLACE FUNCTION public.notify_on_feedback()
RETURNS trigger AS $$
DECLARE
  project_client UUID;
  project_designer UUID;
  project_title TEXT;
  notification_title TEXT;
  notification_message TEXT;
BEGIN
  -- Get project participants
  SELECT client_id, designer_id, title
  INTO project_client, project_designer, project_title
  FROM projects
  WHERE id = NEW.project_id;

  -- Set notification content
  notification_title := '새 피드백이 등록되었습니다';
  notification_message := project_title || ' 프로젝트에 새로운 피드백이 등록되었습니다.';

  -- Notify the other participant (not the feedback creator)
  IF NEW.created_by = project_client AND project_designer IS NOT NULL THEN
    -- Client created feedback, notify designer
    INSERT INTO notifications (user_id, type, title, message, project_id, feedback_id)
    VALUES (project_designer, 'feedback_submitted', notification_title, notification_message, NEW.project_id, NEW.id);
  ELSIF NEW.created_by = project_designer THEN
    -- Designer created feedback, notify client
    INSERT INTO notifications (user_id, type, title, message, project_id, feedback_id)
    VALUES (project_client, 'feedback_submitted', notification_title, notification_message, NEW.project_id, NEW.id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for feedback notifications
CREATE OR REPLACE TRIGGER notify_feedback_created
  AFTER INSERT ON feedback
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_feedback();

-- Function to update project modification count
CREATE OR REPLACE FUNCTION public.update_modification_count()
RETURNS trigger AS $$
BEGIN
  -- Only count modification requests
  IF NEW.is_modification_request = TRUE THEN
    UPDATE projects
    SET current_modifications = current_modifications + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.project_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for modification count
CREATE OR REPLACE TRIGGER update_project_modifications
  AFTER INSERT ON feedback
  FOR EACH ROW EXECUTE FUNCTION public.update_modification_count();

-- RLS policies setup completed
-- Next steps:
-- 1. Test RLS policies with different user roles
-- 2. Add seed data for testing
-- 3. Set up Supabase Storage buckets and policies