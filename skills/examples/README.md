# Examples

This folder tracks real services that have already been standardized with the deployment skills.

## Current examples

- `tlsproxy`
  - Project-owned deploy logic in `linkease-github/tlsproxy/scripts/ops/*.sh`
  - Test deployment from the project repo to `bbs1.koolcenter.com`
  - Production orchestration from `ops-fleet`
- `ddns-server`
  - Project-owned deploy logic in `ddnsto/ddns-server/scripts/ops/*.sh`
  - Test deployment from the project repo to `tunnel.toany.net:2233`
  - Standardized `ops-*` selected-target workflow alongside legacy `test-deploy-*`

Use `skills/SECOND-SERVICE-CHECKLIST.md` when onboarding the next service, then extend this folder once the new workflow has been proven on a real host.
