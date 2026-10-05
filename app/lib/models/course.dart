class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.minutes,
    required this.content,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        title: json['title'] as String,
        minutes: json['minutes'] as int,
        content: json['content'] as String,
      );

  final String id;
  final String title;
  final int minutes;
  final String content;
}

/// Lightweight course info shown in the list.
class CourseSummary {
  const CourseSummary({
    required this.id,
    required this.title,
    required this.icon,
    required this.level,
    required this.summary,
    required this.durationMinutes,
    required this.lessonCount,
    required this.questionCount,
  });

  factory CourseSummary.fromJson(Map<String, dynamic> json) => CourseSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        icon: json['icon'] as String,
        level: json['level'] as String,
        summary: json['summary'] as String,
        durationMinutes: json['durationMinutes'] as int,
        lessonCount: json['lessonCount'] as int,
        questionCount: json['questionCount'] as int,
      );

  final String id;
  final String title;
  final String icon;
  final String level;
  final String summary;
  final int durationMinutes;
  final int lessonCount;
  final int questionCount;
}

/// Full course with description and lessons.
class CourseDetail extends CourseSummary {
  const CourseDetail({
    required super.id,
    required super.title,
    required super.icon,
    required super.level,
    required super.summary,
    required super.durationMinutes,
    required super.lessonCount,
    required super.questionCount,
    required this.description,
    required this.lessons,
    required this.quizTimeLimitSeconds,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    final base = CourseSummary.fromJson(json);
    return CourseDetail(
      id: base.id,
      title: base.title,
      icon: base.icon,
      level: base.level,
      summary: base.summary,
      durationMinutes: base.durationMinutes,
      lessonCount: base.lessonCount,
      questionCount: base.questionCount,
      description: json['description'] as String,
      lessons: (json['lessons'] as List)
          .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
          .toList(),
      quizTimeLimitSeconds:
          (json['quiz'] as Map<String, dynamic>)['timeLimitSeconds'] as int,
    );
  }

  final String description;
  final List<Lesson> lessons;
  final int quizTimeLimitSeconds;
}
