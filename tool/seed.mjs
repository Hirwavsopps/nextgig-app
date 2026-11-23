import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

// Same join as lib/features/messages/domain/conversation_id.dart.
const talentId = 'seed-talent';
const posterId = 'seed-poster';
const mentorId = 'seed-mentor';
const conversation = [mentorId, talentId].sort().join('_');
const password = 'Nextgig1!';

initializeApp({
  credential: applicationDefault(),
  projectId: 'nextgig-app',
});

const auth = getAuth();
const db = getFirestore();

const users = [
  {
    uid: talentId,
    email: 'talent@nextgig.dev',
    name: 'Aline Uwase',
    role: 'talent',
    bio: 'Junior designer and Flutter learner in Kigali.',
  },
  {
    uid: posterId,
    email: 'poster@nextgig.dev',
    name: 'Eric Murenzi',
    role: 'talent',
    bio: 'Posts gigs for Kigali businesses.',
  },
  {
    uid: mentorId,
    email: 'mentor@nextgig.dev',
    name: 'David Mugisha',
    role: 'mentor',
    bio: 'Senior creative lead. Endorses design and Flutter skills.',
  },
];

const gigs = [
  {
    id: 'seed-brand',
    imageUrl: 'https://picsum.photos/id/1060/800/450',
    title: 'Brand Identity & Packaging Redesign',
    description:
      'We are refreshing our single-origin specialty coffee packaging for export. We need a creative talent to design 4 custom coffee pouch illustrations and label layouts celebrating Rwandan landscapes.',
    category: 'Design',
    neighborhood: 'Kacyiru',
    pay: 85000,
    requiredSkills: ['Illustrator', 'Packaging', 'Branding'],
    posterName: 'Kivu Coffee Co.',
    duration: '2 weeks',
    level: 'Jr / Mid',
    applicantCount: 3,
    verifiedClient: true,
    escrowFunded: true,
    deliverables: [
      '4 illustrated packaging labels',
      'Brand style guide sheet',
      'Social media launch assets',
    ],
    mentorName: 'David Mugisha',
    mentorId,
  },
  {
    id: 'seed-wireframes',
    title: 'Mobile App Wireframes & Design System',
    description:
      'Create wireframes for a 6-screen booking app and a small design system with color tokens and reusable components.',
    category: 'Design',
    neighborhood: 'Nyarutarama',
    pay: 45000,
    requiredSkills: ['Figma', 'Tokens'],
    posterName: 'Twiga Logistics',
    duration: '1 week',
    level: 'Jr',
    applicantCount: 5,
    verifiedClient: true,
    escrowFunded: false,
    deliverables: ['6 wireframe screens', 'Color and type tokens'],
  },
  {
    id: 'seed-photo',
    title: 'Product Photography & Short Video Reel',
    description: 'One-day shoot of 20 products plus a 30-second reel.',
    category: 'Photography',
    neighborhood: 'Nyamirambo',
    pay: 30000,
    requiredSkills: ['Photography', 'Editing'],
    posterName: 'Kipepeo Crafts',
    duration: '1 day',
    level: 'Any',
    applicantCount: 8,
    verifiedClient: false,
    escrowFunded: false,
    deliverables: ['15 Photos', '3 Reels'],
  },
  {
    id: 'seed-salon',
    title: 'Build a landing page for a salon',
    description:
      'Simple 3-section responsive page with contact form and gallery.',
    category: 'Tech',
    neighborhood: 'Kimironko',
    pay: 60000,
    requiredSkills: ['HTML', 'CSS', 'Figma'],
    posterName: 'Aline Salon',
    duration: '1 week',
    level: 'Jr / Mid',
    applicantCount: 2,
    verifiedClient: true,
    escrowFunded: true,
    deliverables: ['Responsive landing page', 'Contact form'],
  },
  {
    id: 'seed-tutor',
    title: 'Math tutor for S3 student',
    description: 'Two evenings per week for one month, algebra and geometry.',
    category: 'Tutoring',
    neighborhood: 'Remera',
    pay: 30000,
    requiredSkills: ['Mathematics', 'Teaching'],
    posterName: 'Mutesi Family',
    duration: '4 weeks',
    level: 'Any',
    applicantCount: 1,
    verifiedClient: false,
    escrowFunded: false,
    deliverables: [],
  },
  {
    id: 'seed-laptop',
    title: 'Fix a laptop that will not boot',
    description: 'Diagnose and repair, parts paid separately.',
    category: 'Repair',
    neighborhood: 'Kicukiro',
    pay: 20000,
    requiredSkills: ['Hardware', 'Troubleshooting'],
    posterName: 'Eric M.',
    duration: '2 days',
    level: 'Any',
    applicantCount: 0,
    verifiedClient: false,
    escrowFunded: false,
    deliverables: [],
  },
  {
    id: 'seed-writing',
    title: 'Write product descriptions for an online shop',
    description: '30 short descriptions in English, some in Kinyarwanda.',
    category: 'Writing',
    neighborhood: 'Gikondo',
    pay: 35000,
    requiredSkills: ['Copywriting', 'English', 'Kinyarwanda'],
    posterName: 'Umuco Shop',
    duration: '1 week',
    level: 'Jr / Mid',
    applicantCount: 4,
    verifiedClient: true,
    escrowFunded: false,
    deliverables: ['30 product descriptions'],
  },
  {
    id: 'seed-flutter',
    imageUrl: 'https://picsum.photos/id/180/800/450',
    title: 'Flutter intern for a small booking app',
    description: 'Help build two screens and connect them to Firebase.',
    category: 'Tech',
    neighborhood: 'Nyarutarama',
    pay: 120000,
    requiredSkills: ['Flutter', 'Firebase', 'Dart'],
    posterName: 'BookIt Rwanda',
    duration: '4 weeks',
    level: 'Mid',
    applicantCount: 6,
    verifiedClient: true,
    escrowFunded: true,
    deliverables: ['2 working screens', 'Firestore integration'],
    mentorName: 'David Mugisha',
    mentorId,
  },
];

async function ensureUser(user) {
  try {
    await auth.getUser(user.uid);
    await auth.updateUser(user.uid, {
      email: user.email,
      password,
      displayName: user.name,
      emailVerified: true,
    });
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    await auth.createUser({
      uid: user.uid,
      email: user.email,
      password,
      displayName: user.name,
      emailVerified: true,
    });
  }
  await db.collection('users').doc(user.uid).set(
    {
      name: user.name,
      email: user.email,
      phone: '',
      role: user.role,
      bio: user.bio,
      photoUrl: '',
      createdAt: Timestamp.fromDate(new Date('2026-01-15T00:00:00Z')),
    },
    { merge: true },
  );
}

const deadline = Timestamp.fromDate(new Date(Date.now() + 21 * 24 * 60 * 60 * 1000));
const createdAt = Timestamp.fromDate(new Date());

for (const user of users) {
  await ensureUser(user);
}

// Skill verification demo: reset Aline's submissions so the Figma skill is
// Unverified again and David can endorse it on every rehearsal.
const figmaSkill = db
  .collection('users')
  .doc(talentId)
  .collection('skills')
  .doc('seed-figma-skill');
const staleRequests = await db
  .collection('verificationRequests')
  .where('userId', '==', talentId)
  .get();
const staleEndorsements = await figmaSkill.collection('endorsements').get();
const cleanup = db.batch();
for (const doc of [...staleRequests.docs, ...staleEndorsements.docs]) {
  cleanup.delete(doc.ref);
}
cleanup.delete(db.collection('reviews').doc('seed-done-salon'));
await cleanup.commit();

const batch = db.batch();

// Only accounts listed here can approve or reject skill evidence. Add a
// lecturer or client the same way, or create the document in the Console.
batch.set(db.collection('reviewers').doc(mentorId), {
  name: 'David Mugisha',
  relationship: 'mentor',
  title: 'Senior Creative Lead',
  organization: 'NextGig mentors',
  active: true,
});

for (const gig of gigs) {
  const { id, ...fields } = gig;
  batch.set(db.collection('gigs').doc(id), {
    ...fields,
    posterId,
    deadline,
    createdAt,
  });
}

batch.set(db.collection('users').doc(talentId).collection('skills').doc('seed-flutter-skill'), {
  name: 'Flutter',
  proficiency: 'intermediate',
  portfolio: [{ title: 'Booking screens', imageUrl: '', link: '' }],
  proofUrl: null,
  proofStoragePath: null,
  verified: true,
  verificationStatus: 'verified',
  verifiedAt: createdAt,
  verifiedById: mentorId,
  verifiedByName: 'David Mugisha',
  verifiedByRelationship: 'mentor',
});
batch.set(db.collection('users').doc(talentId).collection('skills').doc('seed-figma-skill'), {
  name: 'Figma',
  proficiency: 'beginner',
  portfolio: [],
  proofUrl: null,
  proofStoragePath: null,
  verified: false,
  verificationStatus: 'unverified',
});
batch.set(
  db
    .collection('users')
    .doc(talentId)
    .collection('skills')
    .doc('seed-flutter-skill')
    .collection('endorsements')
    .doc(mentorId),
  {
    endorserId: mentorId,
    endorserName: 'David Mugisha',
    relationship: 'mentor',
    note: 'Shipped the booking screens with her.',
    createdAt,
  },
);
batch.set(db.collection('applications').doc('seed-applied'), {
  gigId: 'seed-brand',
  gigTitle: 'Brand Identity & Packaging Redesign',
  applicantId: talentId,
  applicantName: 'Aline Uwase',
  posterId,
  status: 'applied',
  createdAt,
});
batch.set(db.collection('applications').doc('seed-done'), {
  gigId: 'seed-flutter',
  gigTitle: 'Flutter intern for a small booking app',
  applicantId: talentId,
  applicantName: 'Aline Uwase',
  posterId,
  status: 'completed',
  createdAt,
});
// Completed but not reviewed yet, for demonstrating a new review.
batch.set(db.collection('applications').doc('seed-done-salon'), {
  gigId: 'seed-salon',
  gigTitle: 'Build a landing page for a salon',
  applicantId: talentId,
  applicantName: 'Aline Uwase',
  posterId,
  status: 'completed',
  createdAt,
});
batch.set(db.collection('reviews').doc('seed-done'), {
  gigId: 'seed-flutter',
  applicationId: 'seed-done',
  reviewerId: posterId,
  revieweeId: talentId,
  reviewerName: 'Eric Murenzi',
  rating: 5,
  comment: 'Finished the two screens and the Firestore connection.',
  createdAt,
});
batch.set(db.collection('users').doc(talentId).collection('earnings').doc('seed-earn-1'), {
  amount: 60000,
  gigTitle: 'Build a landing page for a salon',
  gigId: 'seed-salon',
  mobileMoneyRef: 'MOMO-10021',
  createdAt,
});
batch.set(db.collection('users').doc(talentId).collection('earnings').doc('seed-earn-2'), {
  amount: 30000,
  gigTitle: 'Math tutor for S3 student',
  gigId: 'seed-tutor',
  mobileMoneyRef: 'AIRTEL-4481',
  createdAt,
});
batch.set(db.collection('conversations').doc(conversation), {
  participantIds: [mentorId, talentId].sort(),
  names: {
    [mentorId]: 'David Mugisha',
    [talentId]: 'Aline Uwase',
  },
  lastText: 'Send me the packaging sketches when you can.',
  updatedAt: createdAt,
});
batch.set(db.collection('conversations').doc(conversation).collection('messages').doc('seed-hello'), {
  senderId: mentorId,
  text: 'Send me the packaging sketches when you can.',
  createdAt,
});

await batch.commit();
console.log('Seeded talent@nextgig.dev, poster@nextgig.dev, and mentor@nextgig.dev.');
console.log('Password for all three: Nextgig1!');
