-- Supabase Schema Setup for AI Interview Prep Platform

-- Create profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

-- Create login_history table
CREATE TABLE IF NOT EXISTS public.login_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    login_time TIMESTAMPTZ DEFAULT NOW()
);

-- Create interviews table
CREATE TABLE IF NOT EXISTS public.interviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    domain TEXT NOT NULL,          -- Frontend, Backend, DevOps, Full-Stack
    experience_tier TEXT NOT NULL, -- Junior, Mid, Senior, Lead
    current_step INT NOT NULL DEFAULT 1,
    overall_score INT,
    resume_context TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create interview_steps table
CREATE TABLE IF NOT EXISTS public.interview_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    interview_id UUID NOT NULL REFERENCES public.interviews(id) ON DELETE CASCADE,
    dynamic_question TEXT NOT NULL,
    user_answer TEXT,
    completeness_score FLOAT,
    step_order INT NOT NULL, -- 1 to 5 for technical, 6 for behavioral
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row-Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.login_history ENABLE ROW LEVEL SECURITY;

-- Login History Policies
DROP POLICY IF EXISTS "Users can insert their own logins" ON public.login_history;
CREATE POLICY "Users can insert their own logins" 
    ON public.login_history FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own login history" ON public.login_history;
CREATE POLICY "Users can view their own login history" 
    ON public.login_history FOR SELECT 
    USING (auth.uid() = user_id);

-- Profiles Policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile" 
    ON public.profiles FOR SELECT 
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" 
    ON public.profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Interviews Policies
DROP POLICY IF EXISTS "Users can view their own interviews" ON public.interviews;
CREATE POLICY "Users can view their own interviews" 
    ON public.interviews FOR SELECT 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own interviews" ON public.interviews;
CREATE POLICY "Users can insert their own interviews" 
    ON public.interviews FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own interviews" ON public.interviews;
CREATE POLICY "Users can update their own interviews" 
    ON public.interviews FOR UPDATE 
    USING (auth.uid() = user_id);

-- Interview Steps Policies
DROP POLICY IF EXISTS "Users can view their own interview steps" ON public.interview_steps;
CREATE POLICY "Users can view their own interview steps" 
    ON public.interview_steps FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM public.interviews 
        WHERE public.interviews.id = interview_steps.interview_id 
          AND public.interviews.user_id = auth.uid()
    ));

DROP POLICY IF EXISTS "Users can insert their own interview steps" ON public.interview_steps;
CREATE POLICY "Users can insert their own interview steps" 
    ON public.interview_steps FOR INSERT 
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.interviews 
        WHERE public.interviews.id = interview_steps.interview_id 
          AND public.interviews.user_id = auth.uid()
    ));

DROP POLICY IF EXISTS "Users can update their own interview steps" ON public.interview_steps;
CREATE POLICY "Users can update their own interview steps" 
    ON public.interview_steps FOR UPDATE 
    USING (EXISTS (
        SELECT 1 FROM public.interviews 
        WHERE public.interviews.id = interview_steps.interview_id 
          AND public.interviews.user_id = auth.uid()
    ));

-- Automatically sync Supabase Auth users to profiles table
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    BEGIN
        INSERT INTO public.profiles (id, email, full_name)
        VALUES (
            new.id, 
            new.email, 
            COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'User')
        );
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'handle_new_user trigger error: %', SQLERRM;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
