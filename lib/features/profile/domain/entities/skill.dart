import 'package:equatable/equatable.dart';

class PortfolioItem extends Equatable {
  const PortfolioItem({
    required this.title,
    this.imageUrl = '',
    this.link = '',
  });

  final String title;
  final String imageUrl;
  final String link;

  PortfolioItem copyWith({String? title, String? imageUrl, String? link}) {
    return PortfolioItem(
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      link: link ?? this.link,
    );
  }

  @override
  List<Object?> get props => [title, imageUrl, link];
}

/// A skill on a user's profile. [verified] is set by an endorsement.
class Skill extends Equatable {
  const Skill({
    required this.id,
    required this.name,
    required this.proficiency,
    this.portfolio = const [],
    this.proofUrl,
    this.proofStoragePath,
    this.verified = false,
  });

  final String id;
  final String name;

  /// `beginner`, `intermediate`, or `advanced`.
  final String proficiency;
  final List<PortfolioItem> portfolio;
  final String? proofUrl;
  final String? proofStoragePath;
  final bool verified;

  static const proficiencies = ['beginner', 'intermediate', 'advanced'];

  @override
  List<Object?> get props => [
    id,
    name,
    proficiency,
    portfolio,
    proofUrl,
    proofStoragePath,
    verified,
  ];
}
