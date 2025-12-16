part of '../luciq.dart';

class UploadSymbolsOptions {
  final String? symbolsPath;
  final String? platform;
  final String? apiKey;
  final String? token;
  final String? versionName;
  final String? versionNumber;
  final bool enableNativeSourcemaps;
  final bool verboseLogs;

  UploadSymbolsOptions({
    this.symbolsPath,
    this.platform,
    this.apiKey,
    this.token,
    this.versionName,
    this.versionNumber,
    required this.enableNativeSourcemaps,
    required this.verboseLogs,
  });
}

// ignore: avoid_classes_with_only_static_members
/// This script uploads symbol files (.symbols for Android, .dSYM for iOS) to Luciq endpoint.
/// Usage: luciq upload-symbols [options]
class UploadSymbolsCommand {
  static const String uploadUrl =
      'https://api.instabug.com/api/web/public/flutter-symbol-files';
  static const List<String> validPlatforms = ['android', 'ios'];

  // Helper methods for conditional logging
  static void _logVerbose(bool verbose, String message) {
    if (verbose) {
      stdout.writeln(message);
    }
  }

  static void _logError(String message) {
    stderr.writeln(message);
  }

  static void _logInfo(String message) {
    stdout.writeln(message);
  }

  static ArgParser createParser() {
    final parser = ArgParser()
      ..addFlag('help', abbr: 'h', help: 'Show this help message')
      ..addOption(
        'symbols-path',
        abbr: 's',
        help:
            'Path to the symbols directory (optional - searches current directory recursively if not provided)',
      )
      ..addOption(
        'platform',
        abbr: 'p',
        help:
            'Platform: android or ios (optional - auto-detected from filenames if not provided)',
        allowed: validPlatforms,
      )
      ..addOption(
        'api_key',
        help:
            'Your API key (or set LUCIQ_API_KEY/INSTABUG_API_KEY env variable)',
      )
      ..addOption(
        'token',
        abbr: 't',
        help:
            'Your App Token (or set LUCIQ_APP_TOKEN/INSTABUG_APP_TOKEN env variable)',
      )
      ..addFlag(
        'enable-native-sourcemaps',
        help:
            'Enable native sourcemaps upload (Android mapping.txt and iOS DWARF files)',
      )
      ..addFlag(
        'verbose-logs',
        help: 'Enable verbose logging output',
      )
      ..addOption(
        'version-name',
        help:
            'App version name (e.g., "1.0.0"). If not provided, reads from pubspec.yaml',
      )
      ..addOption(
        'version-number',
        help:
            'App version number/code (e.g., "1"). If not provided, reads from pubspec.yaml',
      );

    return parser;
  }

  static Future<void> execute(ArgResults results) async {
    final options = UploadSymbolsOptions(
      symbolsPath: results['symbols-path'] as String?,
      platform: results['platform'] as String?,
      apiKey: results['api_key'] as String?,
      token: results['token'] as String?,
      versionName: results['version-name'] as String?,
      versionNumber: results['version-number'] as String?,
      enableNativeSourcemaps: results['enable-native-sourcemaps'] as bool,
      verboseLogs: results['verbose-logs'] as bool,
    );

    await uploadSymbols(options);
  }

  static Future<void> uploadSymbols(UploadSymbolsOptions options) async {
    try {
      // Verify Flutter project
      final projectPath = Directory.current.path;
      await _verifyFlutterProject(projectPath);

      // Get upload configs with fallback support
      final applicationToken = await _getApplicationToken(
        projectPath,
        options.token,
        options.verboseLogs,
      );
      final apiKey = _getVariableWithFallback(
        'LUCIQ_API_KEY',
        'INSTABUG_API_KEY',
        options.apiKey,
        verbose: options.verboseLogs,
      );

      // Get version - use provided values or read from pubspec.yaml
      final String versionName;
      final String versionNumber;

      if (options.versionName != null && options.versionName!.isNotEmpty) {
        versionName = options.versionName!;
        versionNumber = options.versionNumber ?? '';
        _logVerbose(
          options.verboseLogs,
          'Using provided version name: $versionName',
        );
        if (versionNumber.isNotEmpty) {
          _logVerbose(
            options.verboseLogs,
            'Using provided version number: $versionNumber',
          );
        }
      } else {
        // Read version from pubspec.yaml
        final version = await _readVersionFromPubspec(projectPath);
        versionName = version.split('+')[0];
        if (version.split('+').length > 1) {
          versionNumber = version.split('+')[1];
        } else {
          versionNumber = options.versionNumber ?? '';
        }
        _logVerbose(
          options.verboseLogs,
          'App version name (from pubspec.yaml): $versionName',
        );
        _logVerbose(
          options.verboseLogs,
          'App version number (from pubspec.yaml): $versionNumber',
        );
      }

      _logVerbose(options.verboseLogs, '🦋 Luciq: Uploading symbol files');

      // Group symbol files by platform based on filename
      final Map<String, List<File>> platformGroups;
      final String basePath;

      if (options.symbolsPath != null) {
        // Use provided symbols path
        basePath = path.isAbsolute(options.symbolsPath!)
            ? options.symbolsPath!
            : path.join(projectPath, options.symbolsPath);
        _logVerbose(options.verboseLogs, 'Symbols path: $basePath');
        platformGroups =
            await _groupFilesByPlatform(basePath, options.verboseLogs);
      } else {
        // Search current directory recursively for symbol files
        basePath = projectPath;
        _logVerbose(
          options.verboseLogs,
          'Searching for symbol files in current directory...',
        );
        platformGroups =
            await _findSymbolFilesRecursively(projectPath, options.verboseLogs);
      }

      if (platformGroups.isEmpty) {
        throw Exception(
          'No symbol files found. Expected files containing ".android" or ".ios" in their names.',
        );
      }

      // Upload each platform group separately (continue on failures)
      final uploadedPlatforms = <String>[];
      final failedPlatforms = <String>[];

      for (final entry in platformGroups.entries) {
        final platform = entry.key;
        final files = entry.value;

        try {
          _logVerbose(
            options.verboseLogs,
            '\n📦 Processing $platform platform (${files.length} file(s)):',
          );
          for (final file in files) {
            _logVerbose(options.verboseLogs, '  ${path.basename(file.path)}');
          }

          // Create zip file for this platform
          final zipFile = await _createZipFileForPlatform(
            basePath,
            files,
            platform,
            options.verboseLogs,
          );

          try {
            // Upload symbols
            await _uploadSymbols(
              zipFile,
              applicationToken,
              apiKey,
              platform,
              versionName,
              versionNumber,
              options.verboseLogs,
            );
            uploadedPlatforms.add(platform);
            _logInfo('✅ $platform symbols uploaded successfully');
          } finally {
            // Clean up zip file
            await zipFile.delete();
          }
        } catch (e) {
          failedPlatforms.add(platform);
          _logError('❌ Failed to upload $platform symbols: $e');
          // Continue with next platform
        }
      }

      if (uploadedPlatforms.isNotEmpty) {
        _logInfo(
          '✅ Successfully uploaded symbol files for platform(s): ${uploadedPlatforms.join(', ')}',
        );
      }

      if (failedPlatforms.isNotEmpty) {
        _logError(
          '⚠️  Failed to upload symbol files for platform(s): ${failedPlatforms.join(', ')}',
        );
      }

      // Handle native sourcemaps if enabled (continue on failures)
      if (options.enableNativeSourcemaps) {
        await _uploadNativeSourcemaps(
          projectPath,
          applicationToken,
          versionName,
          versionNumber,
          options.verboseLogs,
        );
      }

      // Exit with error only if all tasks failed
      if (uploadedPlatforms.isEmpty && failedPlatforms.isNotEmpty) {
        _logError('❌ Some upload tasks failed');
        exit(1);
      }

      if (failedPlatforms.isNotEmpty) {
        // Some tasks succeeded, some failed - exit with warning code
        exit(0);
      }

      exit(0);
    } catch (e) {
      _logError('[Luciq-CLI] Error uploading symbols: $e');
      exit(1);
    }
  }

  static Future<void> _verifyFlutterProject(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (!await projectDir.exists()) {
      throw Exception('Project directory does not exist: $projectPath');
    }

    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw Exception(
        'This is not a Flutter project. pubspec.yaml file not found in $projectPath',
      );
    }
  }

  static String _getVariableWithFallback(
    String primaryName,
    String fallbackName,
    String? optionValue, {
    bool verbose = false,
  }) {
    // Use option value if provided
    if (optionValue != null && optionValue.isNotEmpty) {
      return optionValue;
    }

    // Try primary variable (LUCIQ_ prefixed)
    var variable = Platform.environment[primaryName];
    if (variable != null && variable.isNotEmpty) {
      _logVerbose(verbose, 'Luciq: Using primary variable $primaryName');
      return variable;
    }

    // Try fallback variable (INSTABUG_ prefixed)
    variable = Platform.environment[fallbackName];
    if (variable != null && variable.isNotEmpty) {
      _logVerbose(verbose, 'Luciq: Using fallback variable $fallbackName');
      return variable;
    }

    // Try local.properties file
    final projectPath = Directory.current.path;
    final localPropertiesFile =
        File(path.join(projectPath, 'local.properties'));
    if (localPropertiesFile.existsSync()) {
      final properties = localPropertiesFile.readAsStringSync();
      final lines = properties.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
        final parts = line.split('=');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          if (key == primaryName) {
            _logVerbose(
              verbose,
              'Luciq: Using $primaryName from local.properties',
            );
            return value;
          }
          if (key == fallbackName) {
            _logVerbose(
              verbose,
              'Luciq: Using $fallbackName from local.properties',
            );
            return value;
          }
        }
      }
    }

    throw Exception(
      "$primaryName or $fallbackName not found. Make sure you've added one of these environment variables or pass them as options",
    );
  }

  /// Finds application token using the same logic as find-token.sh
  static Future<String> _getApplicationToken(
    String projectPath,
    String? providedToken,
    bool verbose,
  ) async {
    // If token is provided as option, use it
    if (providedToken != null && providedToken.isNotEmpty) {
      _logVerbose(verbose, 'Luciq: Using token from command line option');
      return providedToken;
    }

    // Try environment variables first (with fallback)
    try {
      final envToken = _getVariableWithFallback(
        'LUCIQ_APP_TOKEN',
        'INSTABUG_APP_TOKEN',
        null,
        verbose: verbose,
      );
      if (envToken.isNotEmpty) {
        return envToken;
      }
    } catch (e) {
      // Continue to file search
    }

    // Try to find token from source files (same logic as find-token.sh)
    try {
      // 1. Check luciq.json file
      final jsonToken = await _findTokenFromJson(projectPath);
      if (jsonToken.isNotEmpty) {
        _logVerbose(verbose, 'Luciq: Found token from luciq.json');
        return jsonToken;
      }

      // 2. Check Dart files for Luciq.init()
      final dartToken = await _findTokenFromDart(projectPath);
      if (dartToken.isNotEmpty) {
        _logVerbose(verbose, 'Luciq: Found token from Dart files: $dartToken');
        return dartToken.trim();
      }

      // 3. Check .env files
      final envFileToken = await _findTokenFromEnvFile(projectPath);
      if (envFileToken.isNotEmpty) {
        _logVerbose(verbose, 'Luciq: Found token from .env file');
        return envFileToken;
      }

      // 4. Check JS/TS files
      final jsToken = await _findTokenFromJsFiles(projectPath);
      if (jsToken.isNotEmpty) {
        _logVerbose(verbose, 'Luciq: Found token from JS/TS files');
        return jsToken;
      }
    } catch (e) {
      // Continue to throw the exception below
    }

    throw Exception(
      'Could not find Luciq app token. Please provide it via --token option, '
      'LUCIQ_APP_TOKEN/INSTABUG_APP_TOKEN environment variable, or in source files.',
    );
  }

  /// Finds token from luciq.json file
  static Future<String> _findTokenFromJson(String projectPath) async {
    final jsonFile = File(path.join(projectPath, 'luciq.json'));
    if (!await jsonFile.exists()) {
      return '';
    }

    try {
      final content = await jsonFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final token = json['app_token'] as String?;
      return token ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Finds token from Dart files (Luciq.init)
  static Future<String> _findTokenFromDart(String projectPath) async {
    try {
      await for (final entity in Directory(projectPath).list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          // Skip node_modules, ios, android directories
          if (entity.path.contains('node_modules') ||
              entity.path.contains('/ios/') ||
              entity.path.contains('/android/')) {
            continue;
          }

          try {
            final content = await entity.readAsString();
            // Look for Luciq.init( with token parameter
            final pattern = RegExp(
              'Luciq\\.init\\s*\\([^)]*token\\s*:\\s*[\'"]([0-9a-zA-Z]+)[\'"]',
              dotAll: true,
            );
            final match = pattern.firstMatch(content);
            if (match != null) {
              return match.group(1) ?? '';
            }
          } catch (e) {
            // Continue to next file
          }
        }
      }
    } catch (e) {
      // Directory traversal error
    }
    return '';
  }

  /// Finds token from .env files
  static Future<String> _findTokenFromEnvFile(String projectPath) async {
    try {
      await for (final entity in Directory(projectPath).list(recursive: true)) {
        if (entity is File &&
            entity.path.endsWith('.env') &&
            !entity.path.contains('node_modules') &&
            !entity.path.contains('/ios/') &&
            !entity.path.contains('/android/')) {
          try {
            final content = await entity.readAsString();
            final lines = content.split('\n');
            for (final line in lines) {
              if (line.trim().startsWith('LUCIQ_APP_TOKEN=')) {
                final parts = line.split('=');
                if (parts.length >= 2) {
                  return parts.sublist(1).join('=').trim();
                }
              }
            }
          } catch (e) {
            // Continue to next file
          }
        }
      }
    } catch (e) {
      // Directory traversal error
    }
    return '';
  }

  /// Finds token from JS/TS files
  static Future<String> _findTokenFromJsFiles(String projectPath) async {
    try {
      await for (final entity in Directory(projectPath).list(recursive: true)) {
        if (entity is File &&
            (entity.path.endsWith('.js') ||
                entity.path.endsWith('.ts') ||
                entity.path.endsWith('.jsx') ||
                entity.path.endsWith('.tsx')) &&
            !entity.path.contains('node_modules') &&
            !entity.path.contains('/ios/') &&
            !entity.path.contains('/android/')) {
          try {
            final content = await entity.readAsString();
            // Look for LUCIQ_APP_TOKEN = "value" or = 'value'
            final pattern = RegExp(
              'LUCIQ_APP_TOKEN\\s*=\\s*[\'"]([0-9a-zA-Z]+)[\'"]',
            );
            final match = pattern.firstMatch(content);
            if (match != null) {
              return match.group(1) ?? '';
            }
          } catch (e) {
            // Continue to next file
          }
        }
      }
    } catch (e) {
      // Directory traversal error
    }
    return '';
  }

  /// Reads version from pubspec.yaml
  static Future<String> _readVersionFromPubspec(String projectPath) async {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw Exception('pubspec.yaml not found in $projectPath');
    }

    final content = await pubspecFile.readAsString();
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('version:')) {
        // Extract version value (e.g., "version: 1.0.0+1" -> "1.0.0+1")
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          return parts[1].trim();
        }
      }
    }

    throw Exception('Version not found in pubspec.yaml');
  }

  /// Groups symbol files by platform based on filename containing ".android" or ".ios"
  static Future<Map<String, List<File>>> _groupFilesByPlatform(
    String symbolsPath,
    bool verbose,
  ) async {
    final symbolsDir = Directory(symbolsPath);
    if (!await symbolsDir.exists()) {
      throw Exception('Symbols directory not found: $symbolsPath');
    }

    final platformGroups = <String, List<File>>{};

    // Scan all files in the symbols directory
    await for (final entity in symbolsDir.list()) {
      if (entity is File) {
        final fileName = path.basename(entity.path);

        // Check if file contains ".android" in its name
        if (fileName.contains('.android')) {
          platformGroups.putIfAbsent('android', () => []).add(entity);
        }
        // Check if file contains ".ios" in its name
        else if (fileName.contains('.ios')) {
          platformGroups.putIfAbsent('ios', () => []).add(entity);
        }
      }
    }

    return platformGroups;
  }

  /// Finds symbol files recursively in the current directory
  static Future<Map<String, List<File>>> _findSymbolFilesRecursively(
    String searchPath,
    bool verbose,
  ) async {
    final platformGroups = <String, List<File>>{};

    // Directories to skip
    final skipDirs = {
      '.git',
      '.dart_tool',
      'build',
      'node_modules',
      '.pub',
      'ios',
      'android',
      'Pods',
      '.symlinks',
      'symlinks',
    };

    await for (final entity in Directory(searchPath).list(recursive: true)) {
      if (entity is File) {
        // Skip files in ignored directories
        final pathSegments = entity.path.split(Platform.pathSeparator);
        if (pathSegments.any((segment) => skipDirs.contains(segment))) {
          continue;
        }

        final fileName = path.basename(entity.path);

        // Only process .symbols files
        if (fileName.endsWith('.symbols')) {
          // Check if file contains ".android" in its name
          if (fileName.contains('.android')) {
            platformGroups.putIfAbsent('android', () => []).add(entity);
          }
          // Check if file contains ".ios" in its name
          else if (fileName.contains('.ios')) {
            platformGroups.putIfAbsent('ios', () => []).add(entity);
          }
        }
      }
    }

    return platformGroups;
  }

  /// Creates a zip file for a specific platform's symbol files
  static Future<File> _createZipFileForPlatform(
    String basePath,
    List<File> files,
    String platform,
    bool verbose,
  ) async {
    final zipEncoder = ZipEncoder();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFileName = 'symbols_${platform}_$timestamp.zip';
    final zipFile = File(path.join(Directory.systemTemp.path, zipFileName));

    final archive = Archive();

    for (final file in files) {
      final relativePath = path.relative(file.path, from: basePath);
      final fileData = await file.readAsBytes();
      archive.addFile(
        ArchiveFile(
          relativePath,
          fileData.length,
          fileData,
        ),
      );
    }

    final zipData = zipEncoder.encode(archive);

    await zipFile.writeAsBytes(zipData);
    _logVerbose(verbose, 'Luciq: Zip file created at ${zipFile.path}');
    return zipFile;
  }

  /// Uploads native sourcemaps (Android mapping.txt and iOS DWARF files)
  static Future<void> _uploadNativeSourcemaps(
    String projectPath,
    String applicationToken,
    String versionName,
    String versionNumber,
    bool verbose,
  ) async {
    _logVerbose(verbose, '\n🔄 Uploading native sourcemaps...');

    // Upload Android mapping.txt (continue on failure)
    try {
      await _uploadAndroidMappingFile(
        projectPath,
        applicationToken,
        versionName,
        versionNumber,
        verbose,
      );
    } catch (e) {
      _logError('❌ Failed to upload Android mapping.txt: $e');
      // Continue with iOS upload
    }

    // Upload iOS DWARF files (continue on failure)
    try {
      await _uploadIosDwarfFiles(projectPath, applicationToken, verbose);
    } catch (e) {
      _logError('❌ Failed to upload iOS DWARF files: $e');
      // Continue - this is okay, we already tried Android
    }
  }

  /// Finds and uploads Android mapping.txt file
  static Future<void> _uploadAndroidMappingFile(
    String projectPath,
    String applicationToken,
    String versionName,
    String versionNumber,
    bool verbose,
  ) async {
    // Look for build/*/outputs/mapping/release/mapping.txt
    final buildDir = Directory(path.join(projectPath, 'build'));
    if (!await buildDir.exists()) {
      _logVerbose(
        verbose,
        '⚠️  Android build directory not found, skipping mapping.txt upload',
      );
      return;
    }

    File? mappingFile;

    // Search in build/*/outputs/mapping/release/mapping.txt
    await for (final entity in buildDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('mapping.txt')) {
        // Check if path matches pattern: build/*/outputs/mapping/release/mapping.txt
        final relativePath = path.relative(entity.path, from: buildDir.path);
        if (relativePath.contains('outputs/mapping/release/mapping.txt')) {
          mappingFile = entity;
          break;
        }
      }
    }

    if (mappingFile == null) {
      _logVerbose(
        verbose,
        '⚠️  Android mapping.txt not found, skipping upload',
      );
      return;
    }

    _logVerbose(verbose, '📦 Found Android mapping.txt: ${mappingFile.path}');

    // Upload to native sourcemaps endpoint
    await _uploadNativeSourcemapFile(
      mappingFile,
      applicationToken,
      'android',
      versionName,
      versionNumber,
      verbose,
    );
  }

  /// Finds and uploads iOS DWARF files
  static Future<void> _uploadIosDwarfFiles(
    String projectPath,
    String applicationToken,
    bool verbose,
  ) async {
    // Look for build/ios/archive/*/dSYMs/*.framework.dSYM/Contents/Resources/DWARF/
    // or ios/build/archive/*/dSYMs/*.framework.dSYM/Contents/Resources/DWARF/
    final possibleBasePaths = [
      path.join(projectPath, 'build', 'ios', 'archive'),
      path.join(projectPath, 'ios', 'build', 'archive'),
    ];

    Directory? dwarfDir;

    for (final basePath in possibleBasePaths) {
      final archiveDir = Directory(basePath);
      if (!await archiveDir.exists()) {
        continue;
      }

      // Search for */*/dSYMs/*.framework.dSYM/Contents/Resources/DWARF/
      await for (final entity in archiveDir.list(recursive: true)) {
        if (entity is Directory && entity.path.endsWith('DWARF')) {
          // Check if path matches pattern: */dSYMs/*.framework.dSYM/Contents/Resources/DWARF/
          final relativePath =
              path.relative(entity.path, from: archiveDir.path);
          if (relativePath.contains('dSYMs') &&
              relativePath.contains('.framework.dSYM') &&
              relativePath.endsWith('DWARF')) {
            dwarfDir = entity;
            break;
          }
        }
      }

      if (dwarfDir != null) {
        break;
      }
    }

    if (dwarfDir == null) {
      _logVerbose(
        verbose,
        '⚠️  iOS DWARF directory not found, skipping upload',
      );
      return;
    }

    _logVerbose(verbose, '📦 Found iOS DWARF directory: ${dwarfDir.path}');

    // Get all files in DWARF directory
    final dwarfFiles = <File>[];
    await for (final entity in dwarfDir.list()) {
      if (entity is File) {
        dwarfFiles.add(entity);
      }
    }

    if (dwarfFiles.isEmpty) {
      _logVerbose(
        verbose,
        '⚠️  No files found in DWARF directory, skipping upload',
      );
      return;
    }

    _logVerbose(verbose, '📦 Found ${dwarfFiles.length} DWARF file(s)');

    // Create zip file with all DWARF files
    final zipFile =
        await _createDwarfZipFile(dwarfDir.path, dwarfFiles, verbose);

    try {
      // Upload to native sourcemaps endpoint
      await _uploadNativeSourcemapZipFile(
        zipFile,
        applicationToken,
        'iOS',
        verbose,
      );
      _logInfo('✅ iOS DWARF files uploaded successfully');
    } finally {
      // Clean up zip file
      await zipFile.delete();
    }
  }

  /// Creates a zip file from DWARF directory files
  static Future<File> _createDwarfZipFile(
    String dwarfDirPath,
    List<File> dwarfFiles,
    bool verbose,
  ) async {
    final zipEncoder = ZipEncoder();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFileName = 'dwarf_ios_$timestamp.zip';
    final zipFile = File(path.join(Directory.systemTemp.path, zipFileName));

    final archive = Archive();

    for (final file in dwarfFiles) {
      final fileName = path.basename(file.path);
      final fileData = await file.readAsBytes();
      archive.addFile(
        ArchiveFile(
          fileName,
          fileData.length,
          fileData,
        ),
      );
    }

    final zipData = zipEncoder.encode(archive);

    await zipFile.writeAsBytes(zipData);
    _logVerbose(verbose, 'Luciq: DWARF zip file created at ${zipFile.path}');
    return zipFile;
  }

  /// Uploads a single file (mapping.txt) to native sourcemaps endpoint
  static Future<void> _uploadNativeSourcemapFile(
    File file,
    String applicationToken,
    String os,
    String versionName,
    String versionNumber,
    bool verbose,
  ) async {
    const uploadUrl = 'https://api.instabug.com/api/sdk/v3/symbols_files';

    _logVerbose(
      verbose,
      'Luciq: Uploading $os mapping file to native sourcemaps endpoint',
    );

    // Create multipart request
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    // Add form fields
    request.fields['os'] = os;
    request.fields['application_token'] = applicationToken;
    request.fields['app_version'] =
        '{"code":"$versionNumber","name":"$versionNumber"}';

    // Add the file
    final fileStream = http.ByteStream(file.openRead());
    final fileLength = await file.length();
    final multipartFile = http.MultipartFile(
      'symbols_file',
      fileStream,
      fileLength,
      filename: file.path.split('/').last,
    );
    request.files.add(multipartFile);

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    _logVerbose(verbose, 'Luciq: Response Code: ${response.statusCode}');
    _logVerbose(verbose, 'Luciq: Response Message: ${response.reasonPhrase}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logError('[Luciq-CLI] Error: Failed to upload native sourcemap file');
      _logVerbose(verbose, 'Response: $responseBody');
      throw Exception('Upload failed with status ${response.statusCode}');
    }

    if (response.statusCode == 200) {
      _logInfo('✅ Successfully uploaded $os native sourcemap file');
    }
  }

  /// Uploads a zip file (DWARF files) to native sourcemaps endpoint
  static Future<void> _uploadNativeSourcemapZipFile(
    File zipFile,
    String applicationToken,
    String os,
    bool verbose,
  ) async {
    const uploadUrl = 'https://api.instabug.com/api/sdk/v3/symbols_files';

    _logVerbose(
      verbose,
      'Luciq: Uploading $os DWARF zip file to native sourcemaps endpoint',
    );

    // Create multipart request
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    // Add form fields
    request.fields['os'] = os;
    request.fields['application_token'] = applicationToken;

    // Add the zip file
    final fileStream = http.ByteStream(zipFile.openRead());
    final fileLength = await zipFile.length();
    final multipartFile = http.MultipartFile(
      'symbols_file',
      fileStream,
      fileLength,
      filename: zipFile.path.split('/').last,
    );
    request.files.add(multipartFile);

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    _logVerbose(verbose, 'Luciq: Response Code: ${response.statusCode}');
    _logVerbose(verbose, 'Luciq: Response Message: ${response.reasonPhrase}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logError(
        '[Luciq-CLI] Error: Failed to upload native sourcemap zip file',
      );
      _logVerbose(verbose, 'Response: $responseBody');
      throw Exception('Upload failed with status ${response.statusCode}');
    }

    if (response.statusCode == 200) {
      _logInfo('✅ Successfully uploaded $os native sourcemap zip file');
    }
  }

  static Future<void> _uploadSymbols(
    File zipFile,
    String applicationToken,
    String apiKey,
    String platform,
    String versionName,
    String versionNumber,
    bool verbose,
  ) async {
    final uploadUrl = platform == 'android'
        ? 'https://api.instabug.com/api/web/public/flutter-symbol-files/android'
        : 'https://api.instabug.com/api/web/public/flutter-symbol-files/ios';

    _logVerbose(verbose, 'Luciq: Uploading to $uploadUrl');

    // Create multipart request
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    // Add form fields
    request.fields['application_token'] = applicationToken;
    request.fields['api_key'] = apiKey;
    request.fields['app_version_name'] = versionName;
    request.fields['app_version_code'] = versionNumber;

    // Add the zip file
    final fileStream = http.ByteStream(zipFile.openRead());
    final fileLength = await zipFile.length();
    final multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: zipFile.path.split('/').last,
    );
    request.files.add(multipartFile);

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    _logVerbose(verbose, 'Luciq: Response Code: ${response.statusCode}');
    _logVerbose(verbose, 'Luciq: Response Message: ${response.reasonPhrase}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logError('[Luciq-CLI] Error: Failed to upload symbol files');
      _logVerbose(verbose, 'Response: $responseBody');
      throw Exception('Upload failed with status ${response.statusCode}');
    }

    if (response.statusCode == 200) {
      _logVerbose(verbose, 'Luciq: Upload successful');
    }
  }
}
