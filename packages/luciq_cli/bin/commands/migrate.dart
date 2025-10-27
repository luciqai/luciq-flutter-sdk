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

    stdout.writeln('✅ Flutter project verified3: $currentPath');
  }

  static Future<void> _executeMigration(MigrateOptions options) async {
    final projectPath = options.projectPath ?? Directory.current.path;
    final projectDir = Directory(projectPath);

    // Load configuration file from package assets
    final config = await _loadConfigFromAssets();

    stdout.writeln('🎯 Starting migration process...');

    if (options.dryRun) {
      stdout.writeln('🔍 DRY RUN MODE - No changes will be made');
    }

    // Step 1: Execute code refactoring LAST to avoid interfering with Git dependency detection
    // Git dependencies need to be processed with original package names

    // Step 2: Update package dependencies first (includes Git dependency handling)
    // This must run BEFORE refactoring to catch Git dependencies with original names
    await _updatePackageDependencies(projectPath, options.dryRun);

    // Step 3: Execute code refactoring (after Git dependencies are handled)
    if (config.refactorMethods.isNotEmpty) {
      stdout.writeln('\n🔄 Starting code refactoring...');
      for (final method in config.refactorMethods) {
        await _executeMethod(method, projectDir, options.dryRun);
      }
    }

    // Step 4: Execute version updates if configured
    if (config.versionUpdates.isNotEmpty) {
      stdout.writeln('\n🔄 Starting version updates...');
      await _executeVersionUpdates(
        config.versionUpdates,
        projectDir,
        options.dryRun,
      );
    }
  }

  static Future<LuciqConfig> _loadConfigFromAssets() async {
    try {
      // Try multiple approaches to find the config file
      final configPaths = _getConfigPaths();

      for (final configPath in configPaths) {
        try {
          final configFile = File(configPath);
          if (await configFile.exists()) {
            return await _loadConfig(configFile);
          }
        } catch (e) {
          // Continue to next path
          continue;
        }
      }

      // If no file found, use embedded config as fallback
      return _getEmbeddedConfig();
    } catch (e) {
      throw Exception('Failed to load configuration: $e');
    }
  }

  static List<String> _getConfigPaths() {
    final scriptDir = path.dirname(Platform.script.toFilePath());

    return [
      // Local development path
      path.join(scriptDir, configFileName),
      // Published package paths
      path.join(scriptDir, '..', 'bin', configFileName),
      path.join(scriptDir, '..', '..', 'bin', configFileName),
      path.join(scriptDir, '..', '..', '..', 'bin', configFileName),
      // Alternative paths for different deployment scenarios
      path.join(scriptDir, '..', '..', '..', '..', 'bin', configFileName),
      path.join(scriptDir, '..', '..', '..', '..', '..', 'bin', configFileName),
    ];
  }

  static LuciqConfig _getEmbeddedConfig() {
    // Embedded configuration as fallback
    return LuciqConfig(
      refactorMethods: [
        const RefactorMethod(
          name: "Instabug to Luciq",
          description: "Replace all instances of Instabug with Luciq",
          searchReplace: [
            SearchReplace(search: "Instabug", replacement: "Luciq"),
            SearchReplace(search: "instabug", replacement: "luciq"),
            SearchReplace(search: "INSTABUG", replacement: "LUCIQ"),
            SearchReplace(search: "IBG", replacement: "LCQ"),
            SearchReplace(search: "ibg", replacement: "lcq"),
            SearchReplace(
              search: "instabug_flutter",
              replacement: "luciq_flutter",
            ),
            SearchReplace(
              search: "instabug_dio_interceptor",
              replacement: "luciq_dio_interceptor",
            ),
            SearchReplace(
              search: "instabug_http_client",
              replacement: "luciq_http_client",
            ),
            SearchReplace(
              search: "instabug_flutter_modular",
              replacement: "luciq_flutter_modular",
            ),
          ],
          targetExtensions: [
            ".dart",
            ".yaml",
            ".h",
            ".m",
            ".java",
            ".kt",
            ".ts",
            ".tsx",
            ".js",
            ".jsx",
            ".json",
          ],
          ignoredDirs: [
            ".symlinks",
            "symlinks",
            "node_modules",
            "build",
            "Pods",
            "vendor",
            ".git",
            "dist",
            "coverage",
            ".next",
            ".nuxt",
            "target",
            ".dart_tool",
            ".pub-cache",
            ".pub",
            ".flutter-plugins",
            ".flutter-plugins-dependencies",
            ".packages",
            "doc/api",
          ],
        ),
      ],
      versionUpdates: [
        const VersionUpdate(
          fromPattern: "instabug_flutter\\s*:\\s*[^\\s]+",
          toPattern: "luciq_flutter: ^18.0.1",
          targetExtensions: [".yaml"],
        ),
        const VersionUpdate(
          fromPattern: "instabug_dio_interceptor\\s*:\\s*[^\\s]+",
          toPattern: "luciq_dio_interceptor: ^3.0.0",
          targetExtensions: [".yaml"],
        ),
        const VersionUpdate(
          fromPattern: "instabug_http_client\\s*:\\s*[^\\s]+",
          toPattern: "luciq_http_client: ^3.0.0",
          targetExtensions: [".yaml"],
        ),
        const VersionUpdate(
          fromPattern: "instabug_flutter_modular\\s*:\\s*[^\\s]+",
          toPattern: "luciq_flutter_modular: ^2.0.0",
          targetExtensions: [".yaml"],
        ),
      ],
    );
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
    // Find all .yaml files in the project
    final yamlFiles = await _findYamlFiles(Directory(projectPath));

    for (final yamlFile in yamlFiles) {
      await _updateSingleYamlFile(yamlFile, dryRun);
    }
  }

  static Future<List<File>> _findYamlFiles(Directory dir) async {
    final yamlFiles = <File>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.yaml')) {
        yamlFiles.add(entity);
      }
    }
    return yamlFiles;
  }

  static Future<void> _updateSingleYamlFile(File yamlFile, bool dryRun) async {
    final content = await yamlFile.readAsString();

    // Define package mappings for regular dependencies
    final packageMappings = {
      'instabug_flutter': 'luciq_flutter: ^18.0.1',
      'instabug_dio_interceptor': 'luciq_dio_interceptor: ^3.0.0',
      'instabug_http_client': 'luciq_http_client: ^3.0.0',
      'instabug_flutter_modular': 'luciq_flutter_modular: ^2.0.0',
    };

    // Define Git dependency mappings
    final gitDependencyMappings = {
      'instabug_flutter': 'luciq_flutter: ^18.0.1\n',
      'instabug_dio_interceptor': 'luciq_dio_interceptor: ^3.0.0\n',
      'instabug_http_client': 'luciq_http_client: ^3.0.0\n',
      'instabug_flutter_modular': 'luciq_flutter_modular: ^2.0.0\n',
    };

    var updatedContent = content;
    var hasChanges = false;

    // Handle Git dependencies FIRST (before regular package dependencies)
    for (final entry in gitDependencyMappings.entries) {
      final oldPackage = entry.key;
      final newPackage = entry.value;

      // Simple and direct Git pattern for the exact structure
      final gitPattern = RegExp(
        '$oldPackage:\\s*\\n\\s*git:\\s*\\n\\s*url:[^\\n]*\\n\\s*ref:[^\\n]*\\n',
        multiLine: true,
      );

      if (gitPattern.hasMatch(updatedContent)) {
        // Use a more sophisticated replacement that maintains YAML structure
        updatedContent = updatedContent.replaceAllMapped(gitPattern, (match) {
          // Get the indentation level from the original match
          // Create properly indented replacement
          return newPackage;
        });

        hasChanges = true;

        if (dryRun) {
          stdout.writeln(
            '📝 Update Git dependency: $oldPackage → $newPackage',
          );
        } else {
          stdout.writeln(
            '📝 Update Git dependency: $oldPackage → $newPackage',
          );
        }
      }
    }

    // Handle regular package dependencies (only if not already processed as Git dependency)
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
            '📝 Update: $oldPackage → $newPackage',
          );
        } else {
          stdout.writeln(
            '📝 Update: $oldPackage → $newPackage',
          );
        }
      }
    }

    if (hasChanges && !dryRun) {
      await yamlFile.writeAsString(updatedContent);
      stdout.writeln('✅ Updated: ${yamlFile.path}');
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
      String newContent;

      // Use regex replacement for patterns that look like regex
      if (update.fromPattern.contains('\\s') ||
          update.fromPattern.contains('\\n')) {
        final regex = RegExp(update.fromPattern, multiLine: true);
        newContent = content.replaceAll(regex, update.toPattern);
      } else {
        newContent = content.replaceAll(update.fromPattern, update.toPattern);
      }

      if (newContent != content) {
        if (dryRun) {
          stdout.writeln('📝Update: ${file.path}');
          return;
        }

        await file.writeAsString(newContent);
        stdout.writeln('📝 Updated: ${file.path}');
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
    await _walkAndProcessFiles(projectDir, method, dryRun);
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
      var newContent = content;
      for (final searchReplace in method.searchReplace) {
        newContent = _contextAwareReplace(newContent, searchReplace);
      }

      if (newContent != content) {
        if (dryRun) {
          stdout.writeln(
            '📝 update content: ${file.path}',
          );
          return;
        }

        await file.writeAsString(newContent);
        stdout.writeln('📝 Updated content: ${file.path}');
      }
    } catch (error) {
      stdout.writeln('❌ Error processing file ${file.path}: $error');
    }
  }

  static bool _isIgnored(String filePath, List<String> ignoredDirs) {
    final pathSegments = filePath.split(Platform.pathSeparator);

    // Check if any ignored directory appears in the path
    for (final ignoredDir in ignoredDirs) {
      if (pathSegments.contains(ignoredDir)) {
        return true;
      }
    }

    // Special handling for common nested ignored directories
    final commonNestedIgnores = [
      'ios/.symlinks',
      'ios/symlinks',
      '.symlinks',
      'symlinks',
    ];

    for (final nestedIgnore in commonNestedIgnores) {
      if (filePath.contains(nestedIgnore)) {
        return true;
      }
    }

    return false;
  }

  static String _contextAwareReplace(
    String content,
    SearchReplace searchReplace,
  ) {
    // More sophisticated context-aware replacement
    var result = content;
    var offset = 0;

    for (final match in RegExp(searchReplace.search, caseSensitive: false)
        .allMatches(content)) {
      final matchStart = match.start;
      final matchEnd = match.end;
      final matchedText = match.group(0)!;

      // Check if this match should be protected
      final shouldProtect = _shouldProtectMatch(content, matchStart, matchEnd);

      if (!shouldProtect) {
        // Apply case-preserving replacement
        String replacement;
        if (matchedText == matchedText.toUpperCase()) {
          replacement = searchReplace.replacement.toUpperCase();
        } else if (matchedText[0] == matchedText[0].toUpperCase()) {
          replacement = searchReplace.replacement[0].toUpperCase() +
              searchReplace.replacement.substring(1);
        } else {
          replacement = searchReplace.replacement.toLowerCase();
        }

        // Replace the match
        result = result.replaceRange(
          matchStart + offset,
          matchEnd + offset,
          replacement,
        );

        // Update offset for subsequent replacements
        offset += replacement.length - (matchEnd - matchStart);
      }
    }

    return result;
  }

  static bool _shouldProtectMatch(String content, int start, int end) {
    // Get the line containing the match
    final beforeMatch = content.substring(0, start);
    final afterMatch = content.substring(end);

    // Find the start and end of the current line
    final lineStart = beforeMatch.lastIndexOf('\n') + 1;
    final lineEnd = afterMatch.indexOf('\n');
    final lineEndPos = lineEnd == -1 ? content.length : end + lineEnd;

    final currentLine = content.substring(lineStart, lineEndPos).trim();

    // Allow changes in import statements (highest priority)
    if (_isImportStatement(currentLine)) {
      return false;
    }

    // Check if we're in a string literal first (but not in import statements)
    if (_isInStringLiteral(content, start) &&
        !_isImportStatement(currentLine)) {
      return true;
    }

    // Allow changes in any line that contains Instabug, Luciq, instabug, or luciq
    // This includes both code and comments, but excludes string literals (checked above)
    if (currentLine.contains('Instabug') ||
        currentLine.contains('Luciq') ||
        currentLine.contains('instabug') ||
        currentLine.contains('luciq')) {
      return false;
    }

    // Check if we're in a URL (but not in import statements)
    if (_isInUrl(currentLine) && !_isImportStatement(currentLine)) {
      return true;
    }

    // Allow changes in package names in pubspec.yaml (but not in string literals)
    if (_isPackageDependency(currentLine) &&
        !_isInStringLiteral(content, start)) {
      return false;
    }

    // Allow changes in class names, method names, etc.
    return false;
  }

  static bool _isInStringLiteral(String content, int position) {
    // Get the line containing the match
    final beforeMatch = content.substring(0, position);
    final afterMatch = content.substring(position);

    // Find the start and end of the current line
    final lineStart = beforeMatch.lastIndexOf('\n') + 1;
    final lineEnd = afterMatch.indexOf('\n');
    final lineEndPos = lineEnd == -1 ? content.length : position + lineEnd;

    final currentLine = content.substring(lineStart, lineEndPos);
    final positionInLine = position - lineStart;

    // Simple check: count unescaped quotes before the position in the current line
    var singleQuotes = 0;
    var doubleQuotes = 0;

    for (var i = 0; i < positionInLine; i++) {
      if (i > 0 && currentLine[i - 1] == '\\') continue; // Skip escaped quotes
      if (currentLine[i] == "'") singleQuotes++;
      if (currentLine[i] == '"') doubleQuotes++;
    }

    // If odd number of quotes, we're inside a string literal
    // ignore: use_is_even_rather_than_modulo
    return (singleQuotes % 2 == 1) || (doubleQuotes % 2 == 1);
  }

  static bool _isInUrl(String line) {
    return line.contains('http://') || line.contains('https://');
  }

  static bool _isImportStatement(String line) {
    return line.startsWith('import ') || line.startsWith('export ');
  }

  static bool _isPackageDependency(String line) {
    // Check if this looks like a package dependency in pubspec.yaml
    return line.contains(':') &&
        (line.contains('^') || line.contains('git:') || line.contains('path:'));
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
