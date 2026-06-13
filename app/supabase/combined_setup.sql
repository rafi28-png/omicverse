-- ============================================================================
-- OMICVERSE COMPLETE DATABASE SETUP SCRIPT
-- Copy this entire file and run it inside the Supabase SQL Editor.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SCHEMAS AND TABLES
-- ----------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL DEFAULT '',
  institution TEXT NOT NULL DEFAULT '',
  app_version TEXT NOT NULL DEFAULT '1.0.0',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.projects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  module      TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.bookmarks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id   TEXT NOT NULL,
  label       TEXT NOT NULL DEFAULT '',
  data        JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.variant_analyses (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  project_id       UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  summary          JSONB NOT NULL DEFAULT '{}',
  reference_genome TEXT NOT NULL DEFAULT 'GRCh38',
  variant_count    INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.expression_analyses (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  project_id       UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  summary          JSONB NOT NULL DEFAULT '{}',
  n_upregulated    INTEGER NOT NULL DEFAULT 0,
  n_downregulated  INTEGER NOT NULL DEFAULT 0,
  gene_count       INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.prs_results (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  project_id       UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  trait_name       TEXT NOT NULL,
  pgs_score_id     TEXT NOT NULL,
  z_score          FLOAT,
  percentile       FLOAT,
  variants_scored  INTEGER,
  coverage_pct     FLOAT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.methylation_results (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  project_id       UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  original_filename TEXT NOT NULL,
  n_samples        INTEGER NOT NULL DEFAULT 0,
  clock_type       TEXT NOT NULL DEFAULT 'horvath',
  sample_results   JSONB NOT NULL DEFAULT '{}',
  cpgs_used        INTEGER,
  coverage_pct     FLOAT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.crispr_designs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  project_id       UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  gene             TEXT NOT NULL,
  cas_type         TEXT NOT NULL,
  guide_sequence   TEXT NOT NULL,
  on_target_score  FLOAT,
  off_target_count INTEGER,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.collaboration_sessions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_code TEXT UNIQUE NOT NULL,
  creator_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title        TEXT NOT NULL DEFAULT '',
  module       TEXT NOT NULL,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.session_participants (
  session_id UUID NOT NULL REFERENCES public.collaboration_sessions(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (session_id, user_id)
);

CREATE TABLE public.session_annotations (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   UUID NOT NULL REFERENCES public.collaboration_sessions(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  screen       TEXT NOT NULL,
  position_x   FLOAT,
  position_y   FLOAT,
  note_text    TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 2. ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------

ALTER TABLE public.profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.variant_analyses     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expression_analyses  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prs_results          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.methylation_results  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crispr_designs       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaboration_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_annotations  ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "own_profile_read"   ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "own_profile_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- All user-owned tables
CREATE POLICY "own_projects"    ON public.projects            FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_bookmarks"   ON public.bookmarks           FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_variants"    ON public.variant_analyses    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_expression"  ON public.expression_analyses FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_prs"         ON public.prs_results         FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_methylation" ON public.methylation_results FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_crispr"      ON public.crispr_designs      FOR ALL USING (auth.uid() = user_id);

-- Collaboration sessions
CREATE POLICY "collab_owner_manage" ON public.collaboration_sessions FOR ALL USING (auth.uid() = creator_id);
CREATE POLICY "collab_participant_read" ON public.collaboration_sessions FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.session_participants sp
    WHERE sp.session_id = id AND sp.user_id = auth.uid()
  ));

-- Session participants
CREATE POLICY "participant_join" ON public.session_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "participant_read" ON public.session_participants FOR SELECT
  USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM public.session_participants sp2
    WHERE sp2.session_id = session_id AND sp2.user_id = auth.uid()
  ));
CREATE POLICY "participant_leave" ON public.session_participants FOR DELETE
  USING (auth.uid() = user_id);

-- Session annotations
CREATE POLICY "annotation_read" ON public.session_annotations FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.session_participants sp
    WHERE sp.session_id = session_annotations.session_id AND sp.user_id = auth.uid()));
CREATE POLICY "annotation_write" ON public.session_annotations FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "annotation_delete" ON public.session_annotations FOR DELETE
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 3. HANDLERS AND TRIGGERS
-- ----------------------------------------------------------------------------

-- Auto-create profile row when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, institution, app_version)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'institution', ''),
    '1.0.0'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER projects_updated_at
  BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER variant_updated_at
  BEFORE UPDATE ON public.variant_analyses FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER expression_updated_at
  BEFORE UPDATE ON public.expression_analyses FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER collab_updated_at
  BEFORE UPDATE ON public.collaboration_sessions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER annotation_updated_at
  BEFORE UPDATE ON public.session_annotations FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ----------------------------------------------------------------------------
-- 4. PERFORMANCE INDEXES
-- ----------------------------------------------------------------------------

CREATE INDEX idx_projects_user      ON public.projects(user_id);
CREATE INDEX idx_projects_created   ON public.projects(created_at DESC);
CREATE INDEX idx_projects_module    ON public.projects(module);
CREATE INDEX idx_bookmarks_user     ON public.bookmarks(user_id);
CREATE INDEX idx_bookmarks_entity   ON public.bookmarks(entity_type, entity_id);
CREATE INDEX idx_variants_user      ON public.variant_analyses(user_id);
CREATE INDEX idx_variants_created   ON public.variant_analyses(created_at DESC);
CREATE INDEX idx_expression_user    ON public.expression_analyses(user_id);
CREATE INDEX idx_prs_user           ON public.prs_results(user_id);
CREATE INDEX idx_prs_trait          ON public.prs_results(trait_name);
CREATE INDEX idx_methylation_user   ON public.methylation_results(user_id);
CREATE INDEX idx_crispr_user        ON public.crispr_designs(user_id);
CREATE INDEX idx_crispr_gene        ON public.crispr_designs(gene);
CREATE INDEX idx_collab_code        ON public.collaboration_sessions(session_code);
CREATE INDEX idx_collab_creator     ON public.collaboration_sessions(creator_id);
CREATE INDEX idx_participants_sess  ON public.session_participants(session_id);
CREATE INDEX idx_participants_user  ON public.session_participants(user_id);
CREATE INDEX idx_annotations_sess   ON public.session_annotations(session_id);

-- ----------------------------------------------------------------------------
-- 5. RPC PROCEDURES (GDPR Safe Account Erasure)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.delete_user_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM public.session_annotations
    WHERE session_id IN (
      SELECT id FROM public.collaboration_sessions WHERE creator_id = uid
    ) OR user_id = uid;

  DELETE FROM public.session_participants WHERE user_id = uid;
  DELETE FROM public.collaboration_sessions WHERE creator_id = uid;
  DELETE FROM public.crispr_designs WHERE user_id = uid;
  DELETE FROM public.methylation_results WHERE user_id = uid;
  DELETE FROM public.prs_results WHERE user_id = uid;
  DELETE FROM public.expression_analyses WHERE user_id = uid;
  DELETE FROM public.variant_analyses WHERE user_id = uid;
  DELETE FROM public.bookmarks WHERE user_id = uid;
  DELETE FROM public.projects WHERE user_id = uid;
  DELETE FROM public.profiles WHERE id = uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_data() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_data() TO authenticated;
