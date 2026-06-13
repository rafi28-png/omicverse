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
