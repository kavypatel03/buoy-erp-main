-- ========================================================
-- BUOY ERP - Real-Time FCM Push Notifications Table Setup
-- Run this in your Supabase SQL Editor to register devices
-- ========================================================

CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    device_type TEXT DEFAULT 'android',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Drop policy if exists then recreate
DROP POLICY IF EXISTS "Allow all on user_fcm_tokens" ON public.user_fcm_tokens;

CREATE POLICY "Allow all on user_fcm_tokens"
ON public.user_fcm_tokens
FOR ALL
TO anon, authenticated, service_role
USING (true)
WITH CHECK (true);

-- Index for instant lookup when sending broadcasts
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_token ON public.user_fcm_tokens (token);

