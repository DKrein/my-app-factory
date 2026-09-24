import 'package:flutter/material.dart';

import '../factory_ui.dart' show FactoryColors, FactorySpacing;

/// Opens [uri] outside the app. The app supplies it, so this package needs no
/// plugin.
typedef OpenLink = Future<void> Function(Uri uri);

/// Attribution for one piece of licensed content.
class CreditEntry {
  const CreditEntry({
    required this.title,
    required this.originalTitle,
    required this.author,
    required this.sourceUrl,
    required this.license,
    required this.licenseUrl,
    this.changes,
  });

  /// What the app calls it, e.g. the sound's name.
  final String title;
  final String originalTitle;
  final String author;
  final String sourceUrl;
  final String license;
  final String licenseUrl;

  /// What was changed from the original, when the license asks to say so.
  final String? changes;
}

/// Every string on the about and credits screens, already translated.
class AboutLabels {
  const AboutLabels({
    required this.title,
    required this.version,
    required this.privacyPolicy,
    required this.contact,
    required this.openSourceLicenses,
    required this.audioCredits,
    required this.creditLine,
    required this.changesLine,
  });

  final String title;
  final String version;
  final String privacyPolicy;
  final String contact;
  final String openSourceLicenses;
  final String audioCredits;
  final String Function(String originalTitle, String author) creditLine;
  final String Function(String changes) changesLine;
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    required this.appName,
    required this.version,
    required this.privacyPolicyUrl,
    required this.supportEmail,
    required this.credits,
    required this.labels,
    required this.openLink,
  });

  final String appName;
  final String version;
  final String privacyPolicyUrl;
  final String supportEmail;
  final List<CreditEntry> credits;
  final AboutLabels labels;
  final OpenLink openLink;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FactoryColors.night,
    appBar: AppBar(
      title: Text(labels.title),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    body: ListView(
      padding: const EdgeInsets.only(bottom: FactorySpacing.xl),
      children: [
        ListTile(
          leading: const _TileIcon(Icons.info_outline),
          title: Text(labels.version),
          subtitle: Text('$appName $version'),
        ),
        const Divider(),
        ListTile(
          leading: const _TileIcon(Icons.privacy_tip_outlined),
          title: Text(labels.privacyPolicy),
          trailing: const _TileIcon(Icons.open_in_new),
          onTap: () => openLink(Uri.parse(privacyPolicyUrl)),
        ),
        ListTile(
          leading: const _TileIcon(Icons.mail_outline),
          title: Text(labels.contact),
          subtitle: Text(supportEmail),
          onTap: () => openLink(Uri(scheme: 'mailto', path: supportEmail)),
        ),
        const Divider(),
        ListTile(
          leading: const _TileIcon(Icons.description_outlined),
          title: Text(labels.openSourceLicenses),
          onTap: () => showLicensePage(
            context: context,
            applicationName: appName,
            applicationVersion: version,
          ),
        ),
        ListTile(
          leading: const _TileIcon(Icons.graphic_eq),
          title: Text(labels.audioCredits),
          trailing: const _TileIcon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CreditsScreen(
                entries: credits,
                labels: labels,
                openLink: openLink,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({
    super.key,
    required this.entries,
    required this.labels,
    required this.openLink,
  });

  final List<CreditEntry> entries;
  final AboutLabels labels;
  final OpenLink openLink;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FactoryColors.night,
    appBar: AppBar(
      title: Text(labels.audioCredits),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    body: ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final changes = entry.changes;
        return ListTile(
          title: Text(entry.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labels.creditLine(entry.originalTitle, entry.author)),
              if (changes != null) Text(labels.changesLine(changes)),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                  foregroundColor: FactoryColors.mist,
                ),
                onPressed: () => openLink(Uri.parse(entry.licenseUrl)),
                child: Text(entry.license),
              ),
            ],
          ),
          trailing: const _TileIcon(Icons.open_in_new),
          onTap: () => openLink(Uri.parse(entry.sourceUrl)),
        );
      },
    ),
  );
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, color: FactoryColors.mutedInk);
}
