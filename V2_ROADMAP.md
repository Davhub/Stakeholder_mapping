# Impact Konnect — V2 Roadmap: Multi-Tenant Platform

**Status:** Planning only. Nothing in this document has been implemented.

**Implementation rule:** Do not begin work on any phase or task below until the
project owner explicitly instructs it (either by name, by phase, or via an
agreed keyword). This file is the canonical plan to work from once that
instruction is given — it supersedes ad-hoc discussion of V2 scope.

---

## 1. Why V2

The app is moving from a single organization's internal tool to a
multi-tenant SaaS platform serving many independent organizations, each with
their own users and stakeholder data, under one platform owner.

## 2. Target role hierarchy

```
                        Impact Konnect

                             YOU
                     Platform Super Admin
                              │
       ┌──────────────────────┼──────────────────────┐
       ▼                      ▼                      ▼
  Organization A         Organization B         Organization C
       │                      │                      │
       ▼                      ▼                      ▼
  Org Super Admin        Org Super Admin        Org Super Admin
       │                      │                      │
  ┌────┴─────┐           ┌────┴─────┐           ┌────┴─────┐
  ▼          ▼           ▼          ▼           ▼          ▼
Mobile     Users       Mobile     Users       Mobile     Users
Admins                 Admins                 Admins
```

- **Platform Super Admin (you)** — approves/rejects organization
  registrations, views organization count and cross-platform usage
  analytics. Operates from a dedicated surface, separate from any single
  organization's data.
- **Org Super Admin** — full control within their own organization: manages
  users, approves/rejects Request Access submissions, invites people
  (single or bulk CSV), assigns roles, views that organization's analytics.
  This is the existing web admin dashboard, scoped to one organization.
- **Mobile Admin** — existing `Admin` role. Adds/edits/views stakeholders
  from the mobile app, scoped to their organization. No web dashboard
  access (already enforced as of the current codebase).
- **User** — existing `User` role. Views stakeholders from the mobile app,
  scoped to their organization.

## 3. Access model change

Public self-signup is removed entirely. It's being replaced by two paths:

**Request Access** (replaces the "Sign Up" button on the sign-in screen)
- Form fields: user's email address, Organization Email.
- Submits to the Org Super Admin (matched by organization email) for
  review.
- On approval: an account is created server-side and an email is sent to
  the user containing their login credentials (email/username + password).

**Invite**
- *Single invite:* Org Super Admin sends a direct invite from the
  dashboard (email + role).
- *Bulk invite:* Org Super Admin uploads a CSV. Expected column format:

  ```
  Email
  Full name
  Role
  ```

  Every row becomes an account; each invited person receives an email with
  their email/username, password, and assigned role.

## 4. Organization registration (new orgs joining the platform)

Public-facing form to create a new organization account. Fields:
- Organization name
- Contact person
- Organization Email
- Phone
- Country

New organizations enter a pending state until the Platform Super Admin
approves them (see Phase 7).

## 5. Known bugs to fix (independent of the rest of V2)

1. **Forgot Password lands in spam.** Root cause: Firebase Auth's default
   email sender. Fixed by the custom domain + transactional email provider
   work in Phase 2 — not fixable by app-code changes alone.
2. **Forgot Password shows "please enter your email" even when a valid
   email is present** in `lib/component/auth_form.dart`. This is a real
   state/validation bug independent of the spam issue and can be fixed
   immediately.

---

## Open decisions (must be resolved before, or very early into, implementation)

These four gate everything downstream. Flagging them here so they're
decided deliberately rather than discovered mid-build.

- [ ] **Email provider.** Pick a transactional email service (e.g.
  SendGrid, Mailgun, Postmark) and verify a custom sending domain. This is
  required for Request Access / Invite emails to exist at all, and is also
  the actual fix for the spam-folder bug.
- [ ] **Firebase billing plan.** Cloud Functions (required for all
  server-side account provisioning and email sending) need the paid
  "Blaze" plan, not the free "Spark" tier. Confirm upgrade before Phase 1
  starts.
- [x] **Existing data migration target.** Resolved: the current production
  data became "Organization 1" (`organizations/organization_1`). Migrated —
  see Phase 2/3 below.
- [x] **Org-wide vs state-scoped access.** Resolved: Org Super Admin
  (and Analyst) on the web dashboard see their whole organization across
  every state; mobile Admin/User accounts stay scoped to their own
  organization *and* their own assigned state. Implemented in
  `AdminFirestoreService` (organization-first, state as an optional
  secondary filter) and in `firestore.rules`'s `isOrgWideRole()`.
- [ ] **Platform Super Admin surface structure.** Decide whether this is a
  new role/route inside the existing `web_admin` Flutter web app, or a
  fully separate app/deployment. Affects Phase 7's implementation shape.

---

## Phased task list

Phases are ordered by dependency — each phase generally assumes the ones
before it are done. Bug fixes in Phase 0 have no dependencies and can ship
whenever.

### Phase 0 — Independent bug fixes
- [ ] Fix "please enter your email" validation bug in `auth_form.dart`'s
  forgot-password flow (fires even with a valid email entered).

### Phase 1 — Backend foundation
- [ ] Stand up Cloud Functions (Node.js + Firebase Admin SDK) in the
  project. This is the foundation every server-side action below depends
  on: creating accounts on behalf of other users, sending email, and
  processing approvals.
- [ ] Wire the chosen email provider (from Open Decisions) into Cloud
  Functions. This also resolves the spam-folder bug once a verified
  custom domain is sending the mail.

### Phase 2 — Multi-tenant data model & security
- [x] Design the `organizations` collection schema. Shipped a minimal
  version (`id`, `name`, `createdAt`, `createdBy` — see
  `lib/web_admin/services/organization_service.dart`); contact
  person/email/phone/country/approval-status fields are still needed once
  Phase 5's registration form exists.
- [x] Add `organizationId` to every user document, regardless of role
  (`UserManagementService.createUser`, `auth_form.dart`'s self-signup
  fallback).
- [x] Add `organizationId` to stakeholders (mobile
  `add_stakeholder_screen.dart` and the web create-stakeholder flow in
  `web_stakeholders_table.dart`). Wards were not tagged — the `wards`
  collection is shared reference/location data (state → LGA → ward
  names), not organization-owned content, so it stays global.
- [x] Rewrite Firestore security rules end-to-end for organization
  scoping, layered on top of the existing role and state scoping. See
  `getUserOrganizationId()` / `isOrgWideRole()` in `firestore.rules`:
  stakeholders and users are now organization-scoped, with mobile
  Admin/User additionally state-scoped and web Super Admin/Analyst
  org-wide.

### Phase 3 — Data migration
- [x] Create the "Organization 1" record (`organizations/organization_1`)
  for the current production tenant.
- [x] Backfill `organizationId` onto all existing stakeholders (1,673) and
  user documents (5) so nothing is orphaned by the schema change. Wards
  were intentionally left untagged (see Phase 2 note above).

### Phase 4 — Client query updates
- [x] Update every mobile app screen/service that queries stakeholders to
  filter by the signed-in user's `organizationId` (in addition to their
  state): `dashboard_screen.dart`, `home_screen.dart`,
  `ward_list_screen.dart`, `stakeholder_list_screen.dart`,
  `association_list_screen.dart`, `association_stakeholder_screen.dart`,
  `ward_stakeholder_screen.dart`, `admin_dashboard_screen.dart`, and
  `dynamic_search_service.dart` (unused by any screen today, but wired for
  when it is).
- [x] Update every web admin screen/service the same way — shifted from
  state-first to organization-first scoping across
  `AdminFirestoreService`, `web_dashboard_home.dart`,
  `web_analytics_screen.dart`, `web_stakeholders_table.dart`, and
  `web_profile_screen.dart`.

### Phase 5 — Organization onboarding
- [ ] Build the public "Create Organization Account" registration form
  (Organization name, Contact person, Organization Email, Phone, Country).
- [ ] Build the organization approval workflow: pending-organization
  state, Platform Super Admin approve/reject actions, notification email
  to the requester on decision.

### Phase 6 — Platform Super Admin dashboard
- [ ] Build the Platform Super Admin surface (structure per the Open
  Decisions item): list/search organizations, approve/reject queue,
  per-organization and cross-platform usage analytics, organization count.

### Phase 7 — Access control overhaul
- [ ] Remove public self-signup from the mobile app; replace the "Sign
  Up" button with "Request Access" (user email + organization email
  fields).
- [ ] Build the Request Access approval workflow on the Org Super Admin
  side: review/approve/reject queue, auto-generate credentials and send
  the credentials email via Cloud Function on approval.
- [ ] Build the single-user Invite flow in the web admin: form to invite
  one person by email + role, sends a credentials email via Cloud
  Function.
- [ ] Build the bulk CSV Invite flow: upload a CSV (`Email`, `Full name`,
  `Role` columns), validate rows, batch-create accounts, send credential
  emails, and surface per-row success/failure results to the admin.

### Phase 8 — Web admin user management
- [ ] Build full user management CRUD in the web admin: list/search/edit/
  deactivate users within the organization, change role, resend invite or
  credentials.

### Phase 9 — Analytics upgrade
- [ ] Upgrade organization-level analytics with a real charting library
  and richer infographics beyond the current bar-list style — geographic
  coverage, engagement, growth trends, and the existing DUA report content.

### Phase 10 — Security hardening
- [ ] Rate-limit access requests to prevent abuse.
- [ ] Validate organization-email domain ownership where feasible (e.g.
  Request Access submissions claiming to belong to an org).
- [ ] Add an audit trail for approvals, invites, and role changes.
- [ ] Full re-review of all Firestore rules once every collection above
  exists.

### Phase 11 — Regression & release
- [ ] Full regression pass: `flutter analyze` + test suite, plus a manual
  walkthrough of every role (Platform Super Admin, Org Super Admin, Mobile
  Admin, User) on both the mobile app and the web admin.
- [ ] Final rebuild of app and web, then Play Store submission — the last
  step, only after everything above is verified working end to end.

---

## Traceability: phase → original task list

For reference, every item from the reviewed 24-item todo list is accounted
for above:

| # | Original task | Phase |
|---|---|---|
| 1 | Email provider decision | Open Decisions |
| 2 | Firebase Blaze plan decision | Open Decisions |
| 3 | Existing data → Organization 1 decision | Open Decisions |
| 4 | Platform Super Admin app structure decision | Open Decisions |
| 5 | Forgot Password validation bug | Phase 0 |
| 6 | Forgot Password spam delivery | Phase 1 |
| 7 | Stand up Cloud Functions backend | Phase 1 |
| 8 | Design multi-tenant data model | Phase 2 (done) |
| 9 | Rewrite Firestore rules for multi-tenancy | Phase 2 (done) |
| 10 | Migrate existing data into Organization 1 | Phase 3 (done) |
| 11 | Update mobile app queries for org scoping | Phase 4 (done) |
| 12 | Update web admin queries for org scoping | Phase 4 (done) |
| 13 | Build organization registration form | Phase 5 |
| 14 | Build organization approval workflow | Phase 5 |
| 15 | Build Platform Super Admin dashboard | Phase 6 |
| 16 | Replace self-signup with Request Access | Phase 7 |
| 17 | Build Request Access approval workflow | Phase 7 |
| 18 | Build single-user invite flow | Phase 7 |
| 19 | Build bulk CSV invite flow | Phase 7 |
| 20 | Build user management CRUD in web admin | Phase 8 |
| 21 | Upgrade analytics/infographics | Phase 9 |
| 22 | Security hardening pass | Phase 10 |
| 23 | Full regression pass | Phase 11 |
| 24 | Final rebuild and Play Store submission | Phase 11 |
