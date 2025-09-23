#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

part 'commands/migrate.dart';

// ignore: avoid_classes_with_only_static_members
/// Command registry for easy management
class CommandRegistry {
  static final Map<String, CommandHandler> _commands = {
    'migrate': CommandHandler(
      parser: MigrateCommand.createParser(),
      execute: MigrateCommand.execute,
    ),
  };

  static Map<String, CommandHandler> get commands => _commands;
  static List<String> get commandNames => _commands.keys.toList();
}

class CommandHandler {
  final ArgParser parser;
  final Function(ArgResults) execute;

  CommandHandler({required this.parser, required this.execute});
}

void main(List<String> args) async {
  final parser = ArgParser()..addFlag('help', abbr: 'h');

  // Add all commands to the parser
  for (final entry in CommandRegistry.commands.entries) {
    parser.addCommand(entry.key, entry.value.parser);
  }

  stdout.writeln('🦋 Luciq CLI');
  stdout.writeln('============');

  try {
    final result = parser.parse(args);

    final command = result.command;
    if (command != null) {
      // Check if help is requested for the subcommand (before mandatory validation)
      if (command['help'] == true) {
        final commandHandler = CommandRegistry.commands[command.name];
        if (commandHandler != null) {
          stdout.writeln('Usage: luciq ${command.name} [options]');
          stdout.writeln(commandHandler.parser.usage);
        }
        return;
      }

      final commandHandler = CommandRegistry.commands[command.name];
      // Extra safety check just in case
      if (commandHandler != null) {
        commandHandler.execute(command);
      } else {
        stderr.writeln('Unknown command: ${command.name}');
        stdout.writeln(
          'Available commands: ${CommandRegistry.commandNames.join(', ')}',
        );
        exit(1);
      }
    } else {
      stderr.writeln('No applicable command found');
      stdout.writeln('Usage: luciq [options] <command>');
      stdout.writeln(
        'Available commands: ${CommandRegistry.commandNames.join(', ')}',
      );
      stdout.writeln('For help on a specific command:');
      stdout.writeln('  luciq <command> --help');
      stdout.writeln(parser.usage);
    }
  } catch (e) {
    stderr.writeln('[Luciq-CLI] Error: $e');
    stdout.writeln(parser.usage);
    exit(1);
  }
}
