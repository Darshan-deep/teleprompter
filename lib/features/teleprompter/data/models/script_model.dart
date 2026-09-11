import '../../domain/entities/script.dart';
import 'json_utils.dart';

/// Storage representation of a [Script].
///
/// Kept separate from the entity so the on-disk shape can evolve independently
/// of the domain, and so malformed records can be dropped instead of throwing.
class ScriptModel {
  const ScriptModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScriptModel.fromEntity(Script script) => ScriptModel(
        id: script.id,
        title: script.title,
        content: script.content,
        createdAt: script.createdAt,
        updatedAt: script.updatedAt,
      );

  /// Returns `null` when the record is unusable (no id, or content that is not
  /// a string). Such records are skipped on load rather than failing the read.
  static ScriptModel? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, Object?> json = JsonUtils.readMap(raw);

    final String id = JsonUtils.readString(json['id']).trim();
    if (id.isEmpty) return null;

    final Object? content = json['content'];
    if (content != null && content is! String) return null;

    final DateTime created = JsonUtils.readDateTime(
      json['createdAt'],
      fallback: DateTime.fromMillisecondsSinceEpoch(0),
    );
    final DateTime updated = JsonUtils.readDateTime(json['updatedAt'], fallback: created);

    return ScriptModel(
      id: id,
      title: JsonUtils.readString(json['title']),
      content: JsonUtils.readString(content),
      createdAt: created,
      updatedAt: updated.isBefore(created) ? created : updated,
    );
  }

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Script toEntity() => Script(
        id: id,
        title: title,
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  String toString() => 'ScriptModel($id, "$title", ${content.length} chars)';
}
