# TDR-004: Cloud Platform

**Date**: 2026-07-27
**Version**: 1.0.0

## Decision
Use **Firebase** (Firestore, Auth, Storage, Functions, Analytics, Remote Config, Crashlytics).

## Alternatives Considered
1. **Supabase** — PostgreSQL-based, open-source, lower cost at scale. Smaller ecosystem, fewer Flutter-specific tools, no built-in Crashlytics equivalent, requires more DevOps.
2. **Custom Backend (Node.js + Postgres + S3)** — Full control, lower long-term cost. Massive upfront development time, requires DevOps, no built-in auth/analytics/crash reporting.
3. **Firebase** — Full managed suite, generous free tier, deep Flutter integration, battle-tested at scale.

## Reasoning
- Firebase Auth handles Google, Email, Apple, anonymous, and account linking out of the box
- Firestore's real-time listeners power the sync engine's change tracker for free
- Cloud Storage handles file uploads with built-in CDN
- Remote Config enables zero-deploy feature flags and prompt template updates
- Firebase Analytics + Crashlytics cover monitoring without third-party tools
- Firestore's security rules are declarative and auditable
- Time to market: Firebase saves months of backend development

## Firestore Cost Estimates (Projected)

| Scale | Users | Reads/mo | Writes/mo | Storage | Est. Cost/mo |
|-------|-------|----------|-----------|---------|--------------|
| Launch | 1,000 | ~500K | ~100K | ~1GB | Free tier |
| Growth | 10,000 | ~5M | ~1M | ~10GB | ~$50-100 |
| Scale | 100,000 | ~50M | ~10M | ~100GB | ~$500-800 |
| Enterprise | 1,000,000 | ~500M | ~100M | ~1TB | ~$5,000-8,000 |

Note: Actual costs depend on message frequency and file storage. AI API costs are separate and typically dominate.

## Trade-offs
- **Gain**: Fastest time to market, managed infrastructure, generous free tier, deep Flutter integration
- **Sacrifice**: Vendor lock-in, Firestore query limitations (no joins, no full-text search), cost grows with reads
