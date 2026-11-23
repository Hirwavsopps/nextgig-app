import 'package:cloud_firestore/cloud_firestore.dart';

/// Fills an empty database, then the signed-in user's skills, one application,
/// a completed application with a review, and two earnings rows.
/// Gigs are posted by [uid] because rules only let the signed-in user create them.
/// The verified skill is written by the owner. A real endorsement still requires
/// a second account, because a user cannot endorse themselves.
Future<void> seedDemoData(
  FirebaseFirestore firestore, {
  required String uid,
  required String name,
}) async {
  final samples = <Map<String, Object?>>[
    {
      'id': 'seed-brand',
      'imageUrl': 'https://picsum.photos/id/1060/800/450',
      'title': 'Brand Identity & Packaging Redesign',
      'description':
          'We are refreshing our single-origin specialty coffee packaging for '
          'export. We need a creative talent to design 4 custom coffee pouch '
          'illustrations and label layouts celebrating Rwandan landscapes.',
      'category': 'Design',
      'neighborhood': 'Kacyiru',
      'pay': 85000,
      'requiredSkills': ['Illustrator', 'Packaging', 'Branding'],
      'posterName': 'Kivu Coffee Co.',
      'posterId': 'seed-user',
      'duration': '2 weeks',
      'level': 'Jr / Mid',
      'applicantCount': 3,
      'verifiedClient': true,
      'escrowFunded': true,
      'deliverables': [
        '4 illustrated packaging labels',
        'Brand style guide sheet',
        'Social media launch assets',
      ],
      'mentorName': 'David Mugisha (Senior Creative Lead)',
    },
    {
      'id': 'seed-wireframes',
      'title': 'Mobile App Wireframes & Design System',
      'description':
          'Create wireframes for a 6-screen booking app and a small design '
          'system with color tokens and reusable components.',
      'category': 'Design',
      'neighborhood': 'Nyarutarama',
      'pay': 45000,
      'requiredSkills': ['Figma', 'Tokens'],
      'posterName': 'Twiga Logistics',
      'posterId': 'seed-user',
      'duration': '1 week',
      'level': 'Jr',
      'applicantCount': 5,
      'verifiedClient': true,
      'escrowFunded': false,
      'deliverables': ['6 wireframe screens', 'Color and type tokens'],
    },
    {
      'id': 'seed-photo',
      'title': 'Product Photography & Short Video Reel',
      'description': 'One-day shoot of 20 products plus a 30-second reel.',
      'category': 'Photography',
      'neighborhood': 'Nyamirambo',
      'pay': 30000,
      'requiredSkills': ['Photography', 'Editing'],
      'posterName': 'Kipepeo Crafts',
      'posterId': 'seed-user',
      'duration': '1 day',
      'level': 'Any',
      'applicantCount': 8,
      'verifiedClient': false,
      'escrowFunded': false,
      'deliverables': ['15 Photos', '3 Reels'],
    },
    {
      'id': 'seed-salon',
      'title': 'Build a landing page for a salon',
      'description':
          'Simple 3-section responsive page with contact form and gallery.',
      'category': 'Tech',
      'neighborhood': 'Kimironko',
      'pay': 60000,
      'requiredSkills': ['HTML', 'CSS', 'Figma'],
      'posterName': 'Aline Salon',
      'posterId': 'seed-user',
      'duration': '1 week',
      'level': 'Jr / Mid',
      'applicantCount': 2,
      'verifiedClient': true,
      'escrowFunded': true,
      'deliverables': ['Responsive landing page', 'Contact form'],
    },
    {
      'id': 'seed-tutor',
      'title': 'Math tutor for S3 student',
      'description':
          'Two evenings per week for one month, algebra and geometry.',
      'category': 'Tutoring',
      'neighborhood': 'Remera',
      'pay': 30000,
      'requiredSkills': ['Mathematics', 'Teaching'],
      'posterName': 'Mutesi Family',
      'posterId': 'seed-user',
      'duration': '4 weeks',
      'level': 'Any',
      'applicantCount': 1,
      'verifiedClient': false,
      'escrowFunded': false,
      'deliverables': [],
    },
    {
      'id': 'seed-laptop',
      'title': 'Fix a laptop that will not boot',
      'description': 'Diagnose and repair, parts paid separately.',
      'category': 'Repair',
      'neighborhood': 'Kicukiro',
      'pay': 20000,
      'requiredSkills': ['Hardware', 'Troubleshooting'],
      'posterName': 'Eric M.',
      'posterId': 'seed-user',
      'duration': '2 days',
      'level': 'Any',
      'applicantCount': 0,
      'verifiedClient': false,
      'escrowFunded': false,
      'deliverables': [],
    },
    {
      'id': 'seed-writing',
      'title': 'Write product descriptions for an online shop',
      'description': '30 short descriptions in English, some in Kinyarwanda.',
      'category': 'Writing',
      'neighborhood': 'Gikondo',
      'pay': 35000,
      'requiredSkills': ['Copywriting', 'English', 'Kinyarwanda'],
      'posterName': 'Umuco Shop',
      'posterId': 'seed-user',
      'duration': '1 week',
      'level': 'Jr / Mid',
      'applicantCount': 4,
      'verifiedClient': true,
      'escrowFunded': false,
      'deliverables': ['30 product descriptions'],
    },
    {
      'id': 'seed-flutter',
      'imageUrl': 'https://picsum.photos/id/180/800/450',
      'title': 'Flutter intern for a small booking app',
      'description': 'Help build two screens and connect them to Firebase.',
      'category': 'Tech',
      'neighborhood': 'Nyarutarama',
      'pay': 120000,
      'requiredSkills': ['Flutter', 'Firebase', 'Dart'],
      'posterName': 'BookIt Rwanda',
      'posterId': 'seed-user',
      'duration': '4 weeks',
      'level': 'Mid',
      'applicantCount': 6,
      'verifiedClient': true,
      'escrowFunded': true,
      'deliverables': ['2 working screens', 'Firestore integration'],
      'mentorName': 'Claudine Uwase (Senior Engineer)',
    },
  ];

  final existingGigs = await firestore.collection('gigs').limit(1).get();
  if (existingGigs.docs.isEmpty) {
    final deadline = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 21)),
    );
    final batch = firestore.batch();
    for (final sample in samples) {
      final id = sample.remove('id')! as String;
      batch.set(firestore.collection('gigs').doc(id), {
        ...sample,
        'posterId': uid,
        'deadline': deadline,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  final skills = firestore.collection('users').doc(uid).collection('skills');
  final existingSkills = await skills.limit(1).get();
  if (existingSkills.docs.isNotEmpty) return;

  final flutter = skills.doc('seed-flutter-skill');
  final figma = skills.doc('seed-figma-skill');
  await flutter.set({
    'name': 'Flutter',
    'proficiency': 'intermediate',
    'portfolio': [
      {'title': 'Booking screens', 'imageUrl': '', 'link': ''},
    ],
    'proofUrl': null,
    'proofStoragePath': null,
    'verified': false,
  });
  await flutter.update({'verified': true});
  await figma.set({
    'name': 'Figma',
    'proficiency': 'beginner',
    'portfolio': const <Map<String, String>>[],
    'proofUrl': null,
    'proofStoragePath': null,
    'verified': false,
  });

  final applied = firestore.collection('applications').doc('seed-applied-$uid');
  await applied.set({
    'gigId': 'seed-brand',
    'gigTitle': 'Brand Identity & Packaging Redesign',
    'applicantId': uid,
    'applicantName': name,
    'posterId': uid,
    'status': 'applied',
    'createdAt': FieldValue.serverTimestamp(),
  });

  final completed = firestore.collection('applications').doc('seed-done-$uid');
  await completed.set({
    'gigId': 'seed-flutter',
    'gigTitle': 'Flutter intern for a small booking app',
    'applicantId': uid,
    'applicantName': name,
    'posterId': uid,
    'status': 'applied',
    'createdAt': FieldValue.serverTimestamp(),
  });
  await completed.update({'status': 'completed'});
  await firestore.collection('reviews').doc(completed.id).set({
    'gigId': 'seed-flutter',
    'applicationId': completed.id,
    'reviewerId': uid,
    'revieweeId': uid,
    'rating': 5,
    'comment': 'Finished the two screens and the Firestore connection.',
    'createdAt': FieldValue.serverTimestamp(),
  });

  final earnings = firestore
      .collection('users')
      .doc(uid)
      .collection('earnings');
  await earnings.doc('seed-earn-1').set({
    'amount': 60000,
    'gigTitle': 'Build a landing page for a salon',
    'gigId': 'seed-salon',
    'mobileMoneyRef': 'MOMO-10021',
    'createdAt': FieldValue.serverTimestamp(),
  });
  await earnings.doc('seed-earn-2').set({
    'amount': 30000,
    'gigTitle': 'Math tutor for S3 student',
    'gigId': 'seed-tutor',
    'mobileMoneyRef': 'AIRTEL-4481',
    'createdAt': FieldValue.serverTimestamp(),
  });
}
