# NextGig data model (Firestore)

Member 3 owns this file. **Field names are frozen once agreed** - the ERD in the report
must match Firestore exactly, so nobody adds fields without updating this file.

## gigs
| Field | Type | Notes |
|---|---|---|
| (doc id) | string | primary key, auto id |
| title | string | |
| description | string | |
| category | string | one of AppConstants.gigCategories |
| neighborhood | string | one of AppConstants.neighborhoods |
| pay | number | RWF |
| requiredSkills | array<string> | |
| posterName | string | |
| posterId | string | FK -> users/{uid} |
| duration | string | e.g. "2 weeks"; empty = flexible |
| level | string | e.g. "Jr / Mid"; empty = any |
| applicantCount | number | default 0 |
| verifiedClient | bool | default false |
| escrowFunded | bool | recorded status only |
| deliverables | array<string> | |
| mentorName | string | optional |
| imageUrl | string | optional, Cloudinary URL |
| createdAt | timestamp | server timestamp; feed is ordered by it |

## users
TODO (member 3): uid (PK), name, email, role, bio, ...

## applications
TODO (member 5): id (PK), gigId (FK), applicantId (FK), status, createdAt

## skills / endorsements / reviews / earnings
TODO (members 3, 4, 6)
