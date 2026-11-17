import 'package:cloud_firestore/cloud_firestore.dart';

/// DEV ONLY. Writes sample gigs to Firestore so the feed is not empty.
/// Works while Firestore is in test mode (or your rules allow the write).
/// Call it once from main.dart, then remove the call.
Future<void> seedSampleGigs(FirebaseFirestore firestore) async {
  final samples = <Map<String, Object?>>[
    {
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

  final batch = firestore.batch();
  for (final sample in samples) {
    final ref = firestore.collection('gigs').doc();
    batch.set(ref, {...sample, 'createdAt': FieldValue.serverTimestamp()});
  }
  await batch.commit();
}
