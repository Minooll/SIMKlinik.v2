# SIMKlinik PRD & Antigravity Prompt Pack

## Files
- `docs/PRD_SIMKlinik.docx`: PRD editable in Word.
- `docs/PRD_SIMKlinik.md`: PRD source Markdown.
- `docs/RLS_MATRIX_DRAFT.md`: worksheet for access policies.
- `prompts/MASTER_PROMPT_Antigravity_SIMKlinik.md`: master prompt.
- `prompts/01_AUDIT_REPOSITORY.md`: repository/Supabase audit.
- `prompts/02_DATABASE_RLS.md`: schema, migration, and RLS.
- `prompts/03_FLUTTER_MOBILE.md`: Flutter implementation.
- `prompts/04_BOOKING_QUEUE_ATOMIC.md`: atomic booking and queue.
- `prompts/05_ADMIN_WEB.md`: admin web implementation.
- `prompts/06_QA_SECURITY_RELEASE.md`: QA/security/release review.

## Recommended use
1. Open the actual project folder in Antigravity.
2. Send the master prompt first. Ask it to complete audit phase and report findings before large edits.
3. Send phase prompts in order, only after prerequisites are satisfied.
4. Never paste a Supabase service_role/secret key into prompts or source code.
5. If the project already has code, commit/backup first and inspect git diff after each phase.
6. Do not call a phase complete unless tests were run and the evidence is recorded.
