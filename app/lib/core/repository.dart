import '../models/course.dart';
import '../models/progress.dart';
import '../models/quiz.dart';
import '../models/user.dart';
import 'api_client.dart';

typedef AuthResult = ({String token, User user});

/// Single place that knows the API's endpoints and JSON shapes.
class LearnRepository {
  LearnRepository(this._api);

  final ApiClient _api;

  AuthResult _auth(dynamic json) => (
        token: json['token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );

  Future<AuthResult> login(String email, String password) async =>
      _auth(await _api.post('/auth/login', {'email': email, 'password': password}));

  Future<AuthResult> register(String name, String email, String password) async =>
      _auth(await _api.post(
          '/auth/register', {'name': name, 'email': email, 'password': password}));

  Future<User> me() async =>
      User.fromJson((await _api.get('/auth/me'))['user'] as Map<String, dynamic>);

  Future<List<CourseSummary>> courses() async => ((await _api.get('/courses')) as List)
      .map((c) => CourseSummary.fromJson(c as Map<String, dynamic>))
      .toList();

  Future<CourseDetail> course(String id) async => CourseDetail.fromJson(
      (await _api.get('/courses/$id')) as Map<String, dynamic>);

  Future<Progress> progress() async =>
      Progress.fromJson((await _api.get('/progress')) as Map<String, dynamic>);

  Future<Progress> setLessonCompleted(String courseId, String lessonId, bool done) async =>
      Progress.fromJson((await _api.put(
          '/courses/$courseId/lessons/$lessonId', {'completed': done})) as Map<String, dynamic>);

  Future<Progress> setCourseCompleted(String courseId, bool done) async =>
      Progress.fromJson((await _api
          .put('/courses/$courseId/completion', {'completed': done})) as Map<String, dynamic>);

  Future<Quiz> quiz(String courseId) async =>
      Quiz.fromJson((await _api.get('/courses/$courseId/quiz')) as Map<String, dynamic>);

  Future<QuizResult> submitQuiz(
          String courseId, List<int?> answers, int durationSeconds) async =>
      QuizResult.fromJson((await _api.post('/courses/$courseId/quiz/submit', {
        'answers': answers,
        'durationSeconds': durationSeconds,
      })) as Map<String, dynamic>);
}
