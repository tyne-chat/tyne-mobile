import 'package:dio/dio.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_dart/export.dart';

/// Fork: what the server reports about a template, in the editor's words. The
/// server sends a code, the name concerned and the position.
String describeGuildCommandTemplateIssue(
  FluxerLocalizations l10n,
  GuildCommandTemplateIssueSchema issue,
) {
  final String name = issue.name ?? '';
  final String problem = switch (issue.code) {
    GuildCommandTemplateIssueCode.unknownTag =>
      l10n.fork.guildCommandIssueUnknownTag(name),
    GuildCommandTemplateIssueCode.unknownFilter =>
      l10n.fork.guildCommandIssueUnknownFilter(name),
    GuildCommandTemplateIssueCode.notClosed =>
      l10n.fork.guildCommandIssueNotClosed(name),
    GuildCommandTemplateIssueCode.tooLong => l10n.fork.guildCommandIssueTooLong,
    GuildCommandTemplateIssueCode.tooLarge =>
      l10n.fork.guildCommandIssueTooLarge,
    GuildCommandTemplateIssueCode.tooSlow => l10n.fork.guildCommandIssueTooSlow,
    GuildCommandTemplateIssueCode.invalid ||
    GuildCommandTemplateIssueCode.$unknown =>
      l10n.fork.guildCommandIssueInvalid,
    GuildCommandTemplateIssueCode.failed => l10n.fork.guildCommandIssueFailed,
  };
  final int? line = issue.line;
  return line == null
      ? problem
      : l10n.fork.guildCommandIssueAt(
          line.toString(),
          (issue.column ?? 1).toString(),
          problem,
        );
}

/// The template's problem in a failed save, when the server named one.
GuildCommandTemplateIssueSchema? guildCommandTemplateIssueOf(Object error) {
  if (error is! DioException) {
    return null;
  }
  final Object? body = error.response?.data;
  final Object? issue = body is Map<String, Object?>
      ? body['template_issue']
      : null;
  return issue is Map<String, Object?>
      ? GuildCommandTemplateIssueSchema.fromJson(issue)
      : null;
}
