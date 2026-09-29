import { danger, fail, schedule, warn } from 'danger';
import collectCoverage, {ReportOptions, ReportType} from '@instabug/danger-plugin-coverage';
import * as fs from 'fs';

// Packages (under packages/<name>/) whose lib/ sources changed in this PR.
const packagesWithSourceChanges = Array.from(
  new Set(
    danger.git.modified_files
      .map((file) => file.match(/^packages\/([^/]+)\/lib\//)?.[1])
      .filter((name): name is string => !!name)
  )
);
const declaredTrivial = danger.github.issue.labels.some(
  (label) => label.name === 'trivial'
);

// Make sure PR has a description.
async function hasDescription() {
  const linesOfCode = (await danger.git.linesOfCode()) ?? 0;
  const hasNoDescription = danger.github.pr.body.includes(
    '> Description goes here'
  );
  if (hasNoDescription && linesOfCode > 10) {
    fail(
      'Please provide a summary of the changes in the pull request description.'
    );
  }

  for (const pkg of packagesWithSourceChanges) {
    const changelog = `packages/${pkg}/CHANGELOG.md`;
    if (!danger.git.modified_files.includes(changelog) && !declaredTrivial) {
      warn(
        `You have not included a CHANGELOG entry for ${pkg}! \nYou can find it at [${changelog}](https://github.com/luciqai/luciq-flutter-sdk/blob/master/${changelog}).`
      );
    }
  }
}

schedule(hasDescription());

// Function to extract the second part of the filename using '-' as a separator
const getLabelFromFilename = (filename: string): string | null => {
  const parts = filename.split('-');
  return parts[1] ? parts[1].replace(/\.[^/.]+$/, '') : null; // Removes extension
};

console.log(JSON.stringify(getLabelFromFilename));
const files = fs.readdirSync('coverage');
let reportOptions:  ReportOptions[] = [];
for (let file of files) {
  reportOptions.push({
    label: getLabelFromFilename(file),
    type: ReportType.LCOV,
    filePath: "coverage/"+file,
    threshold: 80,
  });
}
collectCoverage(reportOptions);

