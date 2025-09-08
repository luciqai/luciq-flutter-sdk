part of '../luciq.dart';

class MigrateOptions {
  final String? projectPath;
  final bool dryRun;
  final bool skipGitCheck;

  MigrateOptions({
    this.projectPath,
    required this.dryRun,
    required this.skipGitCheck,
  });
}

// ignore: avoid_classes_with_only_static_members
/// Migrates the project from Instabug to Luciq.
/// Usage: luciq migrate [options]
class MigrateCommand {
  static const String configFileName = 'luciq_config.json';

  static ArgParser createParser() {
    final parser = ArgParser()
      ..addFlag('help', abbr: 'h', help: 'Show this help message')
      ..addOption(
        'project-path',
        abbr: 'p',
        help: 'Path to your Flutter project (defaults to current directory)',
      )
      ..addFlag(
        'dry-run',
        help: 'Show what would be changed without making changes',
      )
      ..addFlag(
        'skip-git-check',
        help: 'Skip git clean check (use with caution)',
      );

    return parser;
  }

  static Future<void> execute(ArgResults args) async {
    final options = MigrateOptions(
      projectPath: args['project-path'] as String?,
      dryRun: args['dry-run'] as bool,
      skipGitCheck: args['skip-git-check'] as bool,
    );

    stdout.writeln('🔄 Starting Luciq Migration...');

    try {
      if (!options.skipGitCheck) {
        await _checkGitClean();
      }
      await _verifyFlutterProject(options.projectPath);
      await _executeMigration(options);
      await _runFlutterPubGet(options.projectPath, options.dryRun);
      stdout.writeln('✅ Migration completed successfully!');
    } catch (e) {
      stderr.writeln('❌ Migration failed: $e');
      exit(1);
    }
  }

  static Future<void> _checkGitClean() async {
    try {
      final result = await Process.run('git', ['status', '--porcelain']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        stdout.writeln(
          '⚠️ Uncommitted changes detected. Do you want to continue anyway? (y/N)',
        );
        final input = stdin.readLineSync()?.toLowerCase();
        if (input != 'y' && input != 'yes') {
          stdout.writeln('Migration cancelled.');
          exit(0);
        }
        stdout.writeln('Continuing with uncommitted changes...');
      }
    } catch (error) {
      stdout
          .writeln('⚠️ Git check failed, continuing without git validation...');
    }
  }

  static Future<void> _verifyFlutterProject(String? projectPath) async {
    final currentPath = projectPath ?? Directory.current.path;
    final projectDir = Directory(currentPath);

    if (!await projectDir.exists()) {
      throw Exception('Project directory does not exist: $currentPath');
    }

    // Check for pubspec.yaml file (required for Flutter projects)
    final pubspecFile = File(path.join(currentPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw Exception(
        'This is not a Flutter project. pubspec.yaml file not found in $currentPath',
      );
    }

    // Verify it's actually a Flutter project by checking pubspec.yaml content
    final pubspecContent = await pubspecFile.readAsString();
    if (!pubspecContent.contains('flutter:') &&
        !pubspecContent.contains('sdk: flutter')) {
      throw Exception(
        'This is not a Flutter project. pubspec.yaml does not contain Flutter dependencies.',
      );
    }

    // Note: Configuration file is now read from the CLI bin folder

    stdout.writeln('✅ Flutter project verified: $currentPath');
  }

  static Future<void> _executeMigration(MigrateOptions options) async {
    final projectPath = options.projectPath ?? Directory.current.path;
    final projectDir = Directory(projectPath);

    // Load configuration file from CLI bin folder
    final scriptDir = path.dirname(Platform.script.toFilePath());
    final configFile = File(path.join(scriptDir, configFileName));
    final config = await _loadConfig(configFile);

    stdout.writeln('🎯 Starting migration process...');

    if (options.dryRun) {
      stdout.writeln('🔍 DRY RUN MODE - No changes will be made');
    }

    // Step 1: Update package dependencies first
    await _updatePackageDependencies(projectPath, options.dryRun);

    // Step 2: Execute code refactoring
    if (config.refactorMethods.isNotEmpty) {
      stdout.writeln('\n🔄 Starting code refactoring...');
      for (final method in config.refactorMethods) {
        await _executeMethod(method, projectDir, options.dryRun);
      }
    }

    // Step 3: Execute version updates if configured
    if (config.versionUpdates.isNotEmpty) {
      await _executeVersionUpdates(
        config.versionUpdates,
        projectDir,
        options.dryRun,
      );
    }
  }

  static Future<LuciqConfig> _loadConfig(File configFile) async {
    try {
      final content = await configFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return LuciqConfig.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load configuration: $e');
    }
  }

  static Future<void> _updatePackageDependencies(
    String projectPath,
    bool dryRun,
  ) async {
    stdout.writeln('\n📦 Updating package dependencies...');

    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    final content = await pubspecFile.readAsString();

    // Define package mappings
    final packageMappings = {
      'instabug_flutter': 'luciq_flutter: ^18.0.0',
      'instabug_dio_interceptor': 'luciq_dio_interceptor: ^3.0.0',
      'instabug_http_client': 'luciq_http_client: ^3.0.0',
      'instabug_flutter_modular': 'luciq_flutter_modular: ^2.0.0',
    };

    var updatedContent = content;
    var hasChanges = false;

    for (final entry in packageMappings.entries) {
      final oldPackage = entry.key;
      final newPackage = entry.value;

      // Use regex to match package with any version
      final pattern = RegExp('$oldPackage\\s*:\\s*[^\\s]+');
      if (pattern.hasMatch(updatedContent)) {
        updatedContent = updatedContent.replaceAll(pattern, newPackage);
        hasChanges = true;

        if (dryRun) {
          stdout.writeln(
            '📝 [Package Update] Would update: $oldPackage → $newPackage',
          );
        } else {
          stdout.writeln(
            '📝 [Package Update] Updated: $oldPackage → $newPackage',
          );
        }
      }
    }

    if (hasChanges && !dryRun) {
      await pubspecFile.writeAsString(updatedContent);
      stdout.writeln('✅ Package dependencies updated successfully');
    } else if (!hasChanges) {
      stdout.writeln('ℹ️ No Instabug packages found to update');
    }
  }

  static Future<void> _runFlutterPubGet(
    String? projectPath,
    bool dryRun,
  ) async {
    if (dryRun) {
      stdout.writeln('🔍 [DRY RUN] Would run: flutter pub get');
      return;
    }

    stdout.writeln('\n🔄 Running flutter pub get...');
    try {
      final result = await Process.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: projectPath,
      );

      if (result.exitCode == 0) {
        stdout.writeln('✅ flutter pub get completed successfully');
      } else {
        stdout.writeln(
          '⚠️ flutter pub get completed with warnings: ${result.stderr}',
        );
      }
    } catch (e) {
      stdout.writeln('⚠️ Failed to run flutter pub get: $e');
    }
  }

  static Future<void> _executeVersionUpdates(
    List<VersionUpdate> versionUpdates,
    Directory projectDir,
    bool dryRun,
  ) async {
    stdout.writeln('\n🔄 Starting version updates...');

    for (final update in versionUpdates) {
      await _executeVersionUpdate(update, projectDir, dryRun);
    }
  }

  static Future<void> _executeVersionUpdate(
    VersionUpdate update,
    Directory projectDir,
    bool dryRun,
  ) async {
    stdout.writeln(
      '\n📦 Processing version update: ${update.fromPattern} → ${update.toPattern}',
    );

    final files = await _findFilesWithPattern(
      projectDir,
      update.fromPattern,
      update.targetExtensions,
    );

    for (final file in files) {
      await _updateFileVersion(file, update, dryRun);
    }
  }

  static Future<List<File>> _findFilesWithPattern(
    Directory projectDir,
    String pattern,
    List<String> targetExtensions,
  ) async {
    final files = <File>[];

    await for (final entity in projectDir.list(recursive: true)) {
      if (entity is File) {
        final extension = path.extension(entity.path);
        if (targetExtensions.contains(extension)) {
          final content = await entity.readAsString();
          if (content.contains(pattern)) {
            files.add(entity);
          }
        }
      }
    }

    return files;
  }

  static Future<void> _updateFileVersion(
    File file,
    VersionUpdate update,
    bool dryRun,
  ) async {
    try {
      final content = await file.readAsString();
      final newContent =
          content.replaceAll(update.fromPattern, update.toPattern);

      if (newContent != content) {
        if (dryRun) {
          stdout.writeln('📝 [Version Update] Would update: ${file.path}');
          return;
        }

        await file.writeAsString(newContent);
        stdout.writeln('📝 [Version Update] Updated: ${file.path}');
      }
    } catch (e) {
      stdout.writeln('❌ Error updating file ${file.path}: $e');
    }
  }

  static Future<void> _executeMethod(
    RefactorMethod method,
    Directory projectDir,
    bool dryRun,
  ) async {
    stdout.writeln('\n🚀 Starting method: ${method.name}');
    stdout.writeln('   Description: ${method.description}');
    stdout.writeln('   Search/Replace pairs: ${method.searchReplace.length}');
    stdout
        .writeln('   Target extensions: ${method.targetExtensions.join(', ')}');

    final startTime = DateTime.now();

    // Process all files (content only, no renaming)
    stdout.writeln('\n📝 Processing files for method: ${method.name}');
    await _walkAndProcessFiles(projectDir, method, dryRun);

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    stdout.writeln(
      '✅ Method "${method.name}" completed in ${duration.inMilliseconds}ms',
    );
  }

  static Future<void> _walkAndProcessFiles(
    Directory dirPath,
    RefactorMethod method,
    bool dryRun,
  ) async {
    if (_isIgnored(dirPath.path, method.ignoredDirs)) {
      return;
    }

    try {
      final entries = await dirPath.list().toList();

      for (final entry in entries) {
        if (entry is Directory) {
          // Recursively process subdirectories
          await _walkAndProcessFiles(entry, method, dryRun);
        } else if (entry is File) {
          final extension = path.extension(entry.path);
          if (method.targetExtensions.contains(extension)) {
            await _processFile(entry, method, dryRun);
          }
        }
      }
    } catch (error) {
      stdout.writeln('⚠️ Error processing directory ${dirPath.path}: $error');
    }
  }

  static Future<void> _processFile(
    File file,
    RefactorMethod method,
    bool dryRun,
  ) async {
    if (_isIgnored(file.path, method.ignoredDirs)) {
      return;
    }

    try {
      final content = await file.readAsString();
      final newContent = _casePreservingReplace(content, method.searchReplace);

      if (newContent != content) {
        if (dryRun) {
          stdout.writeln(
            '📝 [${method.name}] Would update content: ${file.path}',
          );
          return;
        }

        await file.writeAsString(newContent);
        stdout.writeln('📝 [${method.name}] Updated content: ${file.path}');
      }
    } catch (error) {
      stdout.writeln('❌ Error processing file ${file.path}: $error');
    }
  }

  static bool _isIgnored(String filePath, List<String> ignoredDirs) {
    return ignoredDirs
        .any((dir) => filePath.split(Platform.pathSeparator).contains(dir));
  }

  static String _casePreservingReplace(
    String str,
    List<SearchReplace> searchReplace,
  ) {
    var result = str;

    for (final sr in searchReplace) {
      final regex = RegExp(sr.search, caseSensitive: false);
      result = result.replaceAllMapped(regex, (match) {
        final matchedText = match.group(0)!;
        if (matchedText == matchedText.toUpperCase()) {
          return sr.replacement.toUpperCase();
        }
        if (matchedText[0] == matchedText[0].toUpperCase()) {
          return sr.replacement[0].toUpperCase() + sr.replacement.substring(1);
        }
        return sr.replacement.toLowerCase();
      });
    }

    return result;
  }
}

class LuciqConfig {
  final List<RefactorMethod> refactorMethods;
  final List<VersionUpdate> versionUpdates;

  LuciqConfig({
    required this.refactorMethods,
    required this.versionUpdates,
  });

  factory LuciqConfig.fromJson(Map<String, dynamic> json) {
    final methods = (json['refactorMethods'] as List<dynamic>)
        .map((method) => RefactorMethod.fromJson(method))
        .toList();

    final versionUpdates = (json['versionUpdates'] as List<dynamic>? ?? [])
        .map((update) => VersionUpdate.fromJson(update))
        .toList();

    return LuciqConfig(
      refactorMethods: methods,
      versionUpdates: versionUpdates,
    );
  }
}

class RefactorMethod {
  final String name;
  final String description;
  final List<SearchReplace> searchReplace;
  final List<String> targetExtensions;
  final List<String> ignoredDirs;

  const RefactorMethod({
    required this.name,
    required this.description,
    required this.searchReplace,
    required this.targetExtensions,
    required this.ignoredDirs,
  });

  factory RefactorMethod.fromJson(Map<String, dynamic> json) {
    final searchReplace = (json['searchReplace'] as List<dynamic>)
        .map((sr) => SearchReplace.fromJson(sr))
        .toList();

    return RefactorMethod(
      name: json['name'] as String,
      description: json['description'] as String,
      searchReplace: searchReplace,
      targetExtensions: List<String>.from(json['targetExtensions'] as List),
      ignoredDirs: List<String>.from(json['ignoredDirs'] as List),
    );
  }
}

class SearchReplace {
  final String search;
  final String replacement;

  const SearchReplace({
    required this.search,
    required this.replacement,
  });

  factory SearchReplace.fromJson(Map<String, dynamic> json) {
    return SearchReplace(
      search: json['search'] as String,
      replacement: json['replacement'] as String,
    );
  }
}

class VersionUpdate {
  final String fromPattern;
  final String toPattern;
  final List<String> targetExtensions;

  const VersionUpdate({
    required this.fromPattern,
    required this.toPattern,
    required this.targetExtensions,
  });

  factory VersionUpdate.fromJson(Map<String, dynamic> json) {
    return VersionUpdate(
      fromPattern: json['fromPattern'] as String,
      toPattern: json['toPattern'] as String,
      targetExtensions: List<String>.from(json['targetExtensions'] as List),
    );
  }
}
