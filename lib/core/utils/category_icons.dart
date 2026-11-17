import 'package:flutter/material.dart';

/// Icon shown next to a gig category (card header and detail screen).
IconData categoryIcon(String category) {
  switch (category) {
    case 'Tech':
      return Icons.code;
    case 'Design':
      return Icons.palette_outlined;
    case 'Tutoring':
      return Icons.menu_book_outlined;
    case 'Photography':
      return Icons.photo_camera_outlined;
    case 'Repair':
      return Icons.build_outlined;
    case 'Writing':
      return Icons.edit_outlined;
    case 'Delivery':
      return Icons.local_shipping_outlined;
    default:
      return Icons.work_outline;
  }
}
