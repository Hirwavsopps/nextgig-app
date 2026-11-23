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
| deadline | timestamp | optional |
| createdAt | timestamp | server timestamp; feed is ordered by it |

## users
| Field | Type | Notes |
|---|---|---|
| (doc id) | string | Firebase Auth uid |
| name | string | |
| email | string | |
| phone | string | |
| role | string | talent or poster |
| bio | string | |
| photoUrl | string | Cloudinary URL |
| createdAt | timestamp | |

## users/{uid}/skills
| Field | Type | Notes |
|---|---|---|
| (doc id) | string | |
| name | string | |
| proficiency | string | beginner, intermediate, or advanced |
| portfolio | array<{title, imageUrl, link}> | imageUrl is a Cloudinary URL |
| proofUrl | string | Firebase Storage download URL |
| proofStoragePath | string | |
| verified | bool | set true by an endorsement |

## users/{uid}/skills/{id}/endorsements
| Field | Type | Notes |
|---|---|---|
| endorserId | string | cannot be the skill owner |
| endorserName | string | |
| relationship | string | mentor, lecturer, or client |
| note | string | |
| createdAt | timestamp | |

## applications
| Field | Type | Notes |
|---|---|---|
| (doc id) | string | |
| gigId | string | FK -> gigs |
| gigTitle | string | copied so the list does not re-read the gig |
| applicantId | string | FK -> users |
| applicantName | string | |
| posterId | string | FK -> users |
| status | string | applied, shortlisted, hired, completed, declined |
| createdAt | timestamp | |

## reviews
| Field | Type | Notes |
|---|---|---|
| (doc id) | string | same as the application id, one review each |
| gigId | string | |
| applicationId | string | |
| reviewerId | string | the poster |
| revieweeId | string | the applicant |
| rating | number | 1 to 5 |
| comment | string | |
| createdAt | timestamp | |

## users/{uid}/earnings
| Field | Type | Notes |
|---|---|---|
| (doc id) | string | |
| amount | number | RWF, recorded only |
| gigTitle | string | |
| gigId | string | optional |
| mobileMoneyRef | string | MoMo or Airtel reference, not a live charge |
| createdAt | timestamp | |
