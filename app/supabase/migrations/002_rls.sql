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
