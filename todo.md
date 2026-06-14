# Report Gap Task List

Rule: do one task at a time. Do not start the next task until the current one is checked off.

## Execution Order

- [x] 1. Confirm the report is the target final state and keep it as the source of truth.
- [x] 2. Audit the current project structure against the report and mark every mismatch.
- [x] 3. Align the backend stack with the report target: Supabase/PostgreSQL instead of the current Firebase/Firestore flow.
	- [x] 3.1 Define the Supabase project configuration and environment variables.
	- [x] 3.2 Define the PostgreSQL schema for users, jobs, applications, messages, and reviews.
	- [x] 3.3 Replace Firebase-backed Flutter data access with Supabase-backed access.
	- [x] 3.4 Replace Firebase-backed backend services with Supabase-backed services.
	- [x] 3.5 Verify the new backend path with a narrow end-to-end check.
- [x] 4. Align authentication with the report target: NIC-based login without email-style auth.
- [x] 5. Add or complete English language support so the app matches the report's Sinhala, Tamil, and English claim.
- [x] 6. Implement the chatbot feature described in the report as a career guidance assistant, not just messaging.
- [x] 7. Build the volunteer web panel for registration verification and support handling.
- [x] 8. Add the Google Forms to Google Sheets to backend sync path described in the report.
- [x] 9. Add the Employee Management System described in the report and connect it to the shared backend.
- [x] 12. Seed demo data for users, jobs, categories, skills, and messages so the demo has visible content.
- [ ] 13. Verify the registration flow, login flow, job posting flow, job application flow, and profile flow end to end.
- [ ] 14. Verify multilingual UI coverage across the full app, including labels, buttons, errors, and navigation.
- [ ] 15. Verify the chatbot, SMS, volunteer panel, and employer flows against the report requirements.
- [ ] 16. Prepare a final gap summary stating what changed, what was added, and what still remains.
- [ ] 17. Keep code unchanged unless a task explicitly requires a code change and has been approved.

## Tracking Notes

- [ ] Update this file after each completed task.
- [ ] Keep each task small enough to finish and verify before moving on.
