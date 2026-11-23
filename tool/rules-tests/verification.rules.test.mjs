// Security rules tests for skill verification and reviews.
// Run from tool/rules-tests: npm install && npm test
// The writes below mirror lib/features/verification/data and
// lib/features/reviews/data so the app's real batches are what gets tested.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import { getBytes, ref, uploadBytes } from 'firebase/storage';

const talent = 'talent';
const mentor = 'mentor'; // an authorized reviewer
const fakeMentor = 'fake-mentor'; // signed up with role "mentor", not a reviewer
const client = 'client';
const skillId = 'figma';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-nextgig',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
    storage: {
      rules: readFileSync(new URL('../../storage.rules', import.meta.url), 'utf8'),
    },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', talent), { name: 'Aline', role: 'talent' });
    await setDoc(doc(db, 'users', mentor), { name: 'David', role: 'mentor' });
    await setDoc(doc(db, 'users', fakeMentor), { name: 'Fake', role: 'mentor' });
    await setDoc(doc(db, 'users', client), { name: 'Eric', role: 'talent' });
    await setDoc(doc(db, 'reviewers', mentor), {
      name: 'David',
      relationship: 'mentor',
      active: true,
    });
    await setDoc(doc(db, 'users', talent, 'skills', skillId), {
      name: 'Figma',
      proficiency: 'beginner',
      verified: false,
      verificationStatus: 'unverified',
    });
    // A reviewer's own skill, to test self-endorsement.
    await setDoc(doc(db, 'users', mentor, 'skills', 'design'), {
      name: 'Design',
      proficiency: 'advanced',
      verified: false,
      verificationStatus: 'unverified',
    });
    await setDoc(doc(db, 'applications', 'done'), {
      gigId: 'gig1',
      applicantId: talent,
      posterId: client,
      status: 'completed',
    });
    await setDoc(doc(db, 'applications', 'hired'), {
      gigId: 'gig2',
      applicantId: talent,
      posterId: client,
      status: 'hired',
    });
  });
});

const db = (uid) => env.authenticatedContext(uid).firestore();
const storage = (uid) => env.authenticatedContext(uid).storage();

function newRequest(uid, requestId, overrides = {}) {
  return {
    userId: uid,
    userName: 'Aline',
    skillId,
    skillName: 'Figma',
    evidenceUrl: 'https://example.com/cert.pdf',
    evidenceFileName: 'cert.pdf',
    evidencePath: `verifications/${uid}/${requestId}/cert.pdf`,
    evidenceContentType: 'application/pdf',
    evidenceType: 'courseCertificate',
    note: '',
    status: 'pending',
    submittedAt: serverTimestamp(),
    reviewerId: null,
    reviewerName: '',
    reviewerRelationship: '',
    reviewerComment: '',
    reviewedAt: null,
    ...overrides,
  };
}

/** Same batch as VerificationRemoteDataSource.submit. */
function submit(uid, requestId, { owner = talent, skill = skillId, overrides } = {}) {
  const firestore = db(uid);
  const batch = writeBatch(firestore);
  batch.set(
    doc(firestore, 'verificationRequests', requestId),
    newRequest(owner, requestId, { skillId: skill, ...overrides }),
  );
  batch.update(doc(firestore, 'users', owner, 'skills', skill), {
    verificationStatus: 'pending',
    verificationId: requestId,
  });
  return batch.commit();
}

/** Same batch as VerificationRemoteDataSource.decide. */
function decide(uid, requestId, approve, { owner = talent, skill = skillId, name = 'David', comment = 'Checked the certificate.' } = {}) {
  const firestore = db(uid);
  const skillRef = doc(firestore, 'users', owner, 'skills', skill);
  const batch = writeBatch(firestore);
  batch.update(doc(firestore, 'verificationRequests', requestId), {
    status: approve ? 'verified' : 'rejected',
    reviewerId: uid,
    reviewerName: name,
    reviewerRelationship: 'mentor',
    reviewerComment: comment,
    reviewedAt: serverTimestamp(),
  });
  if (approve) {
    batch.set(doc(skillRef, 'endorsements', uid), {
      endorserId: uid,
      endorserName: name,
      relationship: 'mentor',
      note: comment,
      requestId,
      createdAt: serverTimestamp(),
    });
    batch.update(skillRef, {
      verified: true,
      verificationStatus: 'verified',
      verifiedAt: serverTimestamp(),
      verifiedById: uid,
      verifiedByName: name,
      verifiedByRelationship: 'mentor',
    });
  } else {
    batch.update(skillRef, { verificationStatus: 'rejected' });
  }
  return batch.commit();
}

describe('skills: the owner cannot verify themselves', () => {
  test('creating a skill that is already verified is refused', async () => {
    const ref = doc(db(talent), 'users', talent, 'skills', 'new');
    await assertFails(setDoc(ref, { name: 'X', verified: true }));
    await assertFails(setDoc(ref, { name: 'X', verified: false, verificationStatus: 'verified' }));
    await assertSucceeds(setDoc(ref, { name: 'X', verified: false, verificationStatus: 'unverified' }));
  });

  test('flipping the verified fields directly is refused', async () => {
    const ref = doc(db(talent), 'users', talent, 'skills', skillId);
    await assertFails(updateDoc(ref, { verified: true }));
    await assertFails(updateDoc(ref, { verificationStatus: 'verified' }));
    await assertFails(updateDoc(ref, { verifiedByName: 'Someone' }));
  });

  test('marking pending without a matching request is refused', async () => {
    const ref = doc(db(talent), 'users', talent, 'skills', skillId);
    await assertFails(updateDoc(ref, { verificationStatus: 'pending', verificationId: 'none' }));
  });

  test('plain edits still work', async () => {
    const ref = doc(db(talent), 'users', talent, 'skills', skillId);
    await assertSucceeds(setDoc(ref, { proficiency: 'advanced' }, { merge: true }));
  });

  test('another user cannot edit the skill', async () => {
    const ref = doc(db(client), 'users', talent, 'skills', skillId);
    await assertFails(updateDoc(ref, { proficiency: 'advanced' }));
  });
});

describe('submitting evidence', () => {
  test('the owner can submit, which makes the skill pending', async () => {
    await assertSucceeds(submit(talent, 'r1'));
    const skill = await getDoc(doc(db(talent), 'users', talent, 'skills', skillId));
    if (skill.data().verificationStatus !== 'pending') throw new Error('not pending');
  });

  test('a request created as already verified is refused', async () => {
    await assertFails(submit(talent, 'r1', { overrides: { status: 'verified' } }));
    await assertFails(submit(talent, 'r1', { overrides: { reviewerId: talent } }));
  });

  test('evidence must point at the owner\'s own Storage folder', async () => {
    await assertFails(
      submit(talent, 'r1', { overrides: { evidencePath: 'verifications/someone/r1/cert.pdf' } }),
    );
  });

  test('nobody can submit for someone else\'s skill', async () => {
    await assertFails(submit(client, 'r1'));
  });

  test('a pending skill cannot be resubmitted or renamed', async () => {
    await submit(talent, 'r1');
    await assertFails(submit(talent, 'r2'));
    const ref = doc(db(talent), 'users', talent, 'skills', skillId);
    await assertFails(setDoc(ref, { name: 'Brain surgery' }, { merge: true }));
    await assertSucceeds(setDoc(ref, { proficiency: 'intermediate' }, { merge: true }));
  });
});

describe('reviewing evidence', () => {
  beforeEach(() => submit(talent, 'r1'));

  test('an authorized reviewer can approve', async () => {
    await assertSucceeds(decide(mentor, 'r1', true));
    const skill = await getDoc(doc(db(client), 'users', talent, 'skills', skillId));
    const data = skill.data();
    if (!data.verified || data.verificationStatus !== 'verified' || data.verifiedById !== mentor) {
      throw new Error(`unexpected skill ${JSON.stringify(data)}`);
    }
  });

  test('a user who signed up as "mentor" but is not a reviewer cannot approve', async () => {
    await assertFails(decide(fakeMentor, 'r1', true, { name: 'Fake' }));
  });

  test('the owner cannot approve their own request', async () => {
    await assertFails(decide(talent, 'r1', true, { name: 'Aline' }));
  });

  test('a reviewer cannot endorse their own skill', async () => {
    await submit(mentor, 'own', { owner: mentor, skill: 'design', overrides: { skillName: 'Design', userName: 'David' } });
    await assertFails(decide(mentor, 'own', true, { owner: mentor, skill: 'design' }));
  });

  test('a reviewer cannot sign with someone else\'s name', async () => {
    await assertFails(decide(mentor, 'r1', true, { name: 'Prof. Famous' }));
  });

  test('a decision needs a comment', async () => {
    await assertFails(decide(mentor, 'r1', true, { comment: '' }));
  });

  test('a request is decided only once, and only one endorsement per reviewer', async () => {
    await assertSucceeds(decide(mentor, 'r1', true));
    await assertFails(decide(mentor, 'r1', false));
    await assertFails(
      setDoc(doc(db(mentor), 'users', talent, 'skills', skillId, 'endorsements', mentor), {
        endorserId: mentor,
        endorserName: 'David',
        relationship: 'mentor',
        requestId: 'r1',
        createdAt: serverTimestamp(),
      }),
    );
  });

  test('approving without also verifying the skill is refused', async () => {
    const firestore = db(mentor);
    await assertFails(
      updateDoc(doc(firestore, 'verificationRequests', 'r1'), {
        status: 'verified',
        reviewerId: mentor,
        reviewerName: 'David',
        reviewerRelationship: 'mentor',
        reviewerComment: 'Looks good',
        reviewedAt: serverTimestamp(),
      }),
    );
  });

  test('after a rejection the owner can send new evidence', async () => {
    await assertSucceeds(decide(mentor, 'r1', false, { comment: 'Certificate is blurry.' }));
    await assertSucceeds(submit(talent, 'r2'));
  });

  test('a deactivated reviewer cannot approve', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'reviewers', mentor), { active: false }),
    );
    await assertFails(decide(mentor, 'r1', true));
  });
});

describe('who can read requests', () => {
  beforeEach(() => submit(talent, 'r1'));

  test('owner and reviewers can read; other users cannot', async () => {
    await assertSucceeds(getDoc(doc(db(talent), 'verificationRequests', 'r1')));
    await assertSucceeds(getDoc(doc(db(mentor), 'verificationRequests', 'r1')));
    await assertFails(getDoc(doc(db(client), 'verificationRequests', 'r1')));
  });

  test('only reviewers can list the pending queue', async () => {
    const pending = (uid) =>
      getDocs(query(collection(db(uid), 'verificationRequests'), where('status', '==', 'pending')));
    await assertSucceeds(pending(mentor));
    await assertFails(pending(fakeMentor));
  });

  test('nobody can make themselves a reviewer', async () => {
    await assertFails(
      setDoc(doc(db(fakeMentor), 'reviewers', fakeMentor), {
        name: 'Fake',
        relationship: 'mentor',
        active: true,
      }),
    );
  });

  test('requests cannot be deleted', async () => {
    const { deleteDoc } = await import('firebase/firestore');
    await assertFails(deleteDoc(doc(db(talent), 'verificationRequests', 'r1')));
  });
});

describe('reviews', () => {
  const review = (overrides = {}) => ({
    gigId: 'gig1',
    applicationId: 'done',
    reviewerId: client,
    reviewerName: 'Eric',
    revieweeId: talent,
    rating: 5,
    comment: 'Great work, delivered on time.',
    createdAt: serverTimestamp(),
    ...overrides,
  });

  test('the client of a completed gig can review once', async () => {
    const ref = doc(db(client), 'reviews', 'done');
    await assertSucceeds(setDoc(ref, review()));
    await assertFails(setDoc(ref, review({ rating: 1 })));
    await assertFails(updateDoc(ref, { rating: 1 }));
  });

  test('the gig must be completed', async () => {
    await assertFails(
      setDoc(doc(db(client), 'reviews', 'hired'), review({ applicationId: 'hired', gigId: 'gig2' })),
    );
  });

  test('only the client on the gig can review', async () => {
    await assertFails(setDoc(doc(db(mentor), 'reviews', 'done'), review({ reviewerId: mentor, reviewerName: 'David' })));
    await assertFails(setDoc(doc(db(talent), 'reviews', 'done'), review({ reviewerId: talent, reviewerName: 'Aline' })));
  });

  test('rating, comment and name are validated', async () => {
    const ref = doc(db(client), 'reviews', 'done');
    await assertFails(setDoc(ref, review({ rating: 6 })));
    await assertFails(setDoc(ref, review({ rating: 0 })));
    await assertFails(setDoc(ref, review({ rating: 4.5 })));
    await assertFails(setDoc(ref, review({ comment: 'ok' })));
    await assertFails(setDoc(ref, review({ comment: 'x'.repeat(501) })));
    await assertFails(setDoc(ref, review({ reviewerName: 'Someone Famous' })));
    await assertFails(setDoc(ref, review({ revieweeId: mentor })));
  });
});

describe('evidence files in Storage', () => {
  const pdf = new Uint8Array([0x25, 0x50, 0x44, 0x46]);
  const path = `verifications/${talent}/r1/cert.pdf`;

  test('the owner can upload a PDF or image to their own folder', async () => {
    await assertSucceeds(uploadBytes(ref(storage(talent), path), pdf, { contentType: 'application/pdf' }));
    await assertSucceeds(
      uploadBytes(ref(storage(talent), `verifications/${talent}/r2/a.png`), pdf, { contentType: 'image/png' }),
    );
  });

  test('uploads to another user\'s folder, wrong types and large files are refused', async () => {
    await assertFails(uploadBytes(ref(storage(client), path), pdf, { contentType: 'application/pdf' }));
    await assertFails(
      uploadBytes(ref(storage(talent), `verifications/${talent}/r1/x.exe`), pdf, { contentType: 'application/octet-stream' }),
    );
    const big = new Uint8Array(5 * 1024 * 1024 + 1);
    await assertFails(
      uploadBytes(ref(storage(talent), `verifications/${talent}/r1/big.pdf`), big, { contentType: 'application/pdf' }),
    );
  });

  test('only the owner and reviewers can open evidence', async () => {
    await uploadBytes(ref(storage(talent), path), pdf, { contentType: 'application/pdf' });
    await assertSucceeds(getBytes(ref(storage(talent), path)));
    await assertSucceeds(getBytes(ref(storage(mentor), path)));
    await assertFails(getBytes(ref(storage(client), path)));
    await assertFails(getBytes(ref(storage(fakeMentor), path)));
  });
});
