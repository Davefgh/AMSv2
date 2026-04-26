import 'instructor_model.dart';
import 'subject_model.dart';
import 'schedule_model.dart';
import 'classroom_model.dart';

class StudentSubjectDetail {
  final Subject subject;
  final Schedule schedule;
  final Instructor instructor;
  final Classroom classroom;

  StudentSubjectDetail({
    required this.subject,
    required this.schedule,
    required this.instructor,
    required this.classroom,
  });

  factory StudentSubjectDetail.fromJson(Map<String, dynamic> json) {
    return StudentSubjectDetail(
      subject: Subject.fromJson(json['subject'] as Map<String, dynamic>),
      schedule: Schedule.fromJson(json['schedule'] as Map<String, dynamic>),
      instructor:
          Instructor.fromJson(json['instructor'] as Map<String, dynamic>),
      classroom: Classroom.fromJson(json['classroom'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.toJson(),
      'schedule': schedule.toJson(),
      'instructor': instructor.toJson(),
      'classroom': classroom.toJson(),
    };
  }
}
