const fs = require('fs');
const path = require('path');

// 1. Read pubspec.yaml
const pubspecPath = path.join(__dirname, '../pubspec.yaml');
let pubspec = fs.readFileSync(pubspecPath, 'utf8');

// Match version: X.Y.Z+B
const versionMatch = pubspec.match(/version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)/);

if (!versionMatch) {
  console.error('Could not find version in pubspec.yaml');
  process.exit(1);
}

const major = parseInt(versionMatch[1], 10);
const minor = parseInt(versionMatch[2], 10);
const patch = parseInt(versionMatch[3], 10) + 1; // Increment patch
const build = parseInt(versionMatch[4], 10) + 1; // Increment build number

const newVersionStr = `${major}.${minor}.${patch}`;
const newFullVersion = `${newVersionStr}+${build}`;

// Update pubspec.yaml
pubspec = pubspec.replace(/version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)/, `version: ${newFullVersion}`);
fs.writeFileSync(pubspecPath, pubspec, 'utf8');
console.log(`✅ Bumped pubspec.yaml to: ${newFullVersion}`);

// 2. Update lib/app/constants/app_constants.dart
const constantsPath = path.join(__dirname, '../lib/app/constants/app_constants.dart');
const now = new Date();
const dateStr = now.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

const constantsContent = `class AppConstants {
  static const String appName = 'Buoy ERP';
  static const String companyName = 'Buoy';
  static const String tagline = 'Smart Inventory & Stock Management Solution';
  static const String footerMessage = 'Manage your factory anytime, anywhere.';
  static const String copyright = '© 2026 Buoy';

  // Auto-incremented release version & build info
  static const String appVersion = '${newVersionStr}';
  static const int buildNumber = ${build};
  static const String buildDate = '${dateStr}';
  static String get fullVersionString => 'v\$appVersion (Build \$buildNumber)';
}
`;

fs.writeFileSync(constantsPath, constantsContent, 'utf8');
console.log(`✅ Updated AppConstants with version: v${newVersionStr} (Build ${build})`);

// 3. Update backend/config/version.json for In-App Live Update Engine
const versionJsonPath = path.join(__dirname, '../backend/config/version.json');
const versionJsonData = {
  latestVersion: newVersionStr,
  buildNumber: build,
  downloadUrl: 'https://github.com/kavypatel03/buoy-erp-main/raw/main/web/download/buoy-erp.apk',
  releaseNotes: 'Continuous production release with latest factory performance and features.',
  releaseDate: now.toISOString(),
  forceUpdate: false
};
fs.writeFileSync(versionJsonPath, JSON.stringify(versionJsonData, null, 2), 'utf8');
console.log(`✅ Updated backend/config/version.json with build ${build}`);

// 4. Output for shell scripts if needed
if (process.argv.includes('--env')) {
  fs.writeFileSync(path.join(__dirname, 'version.env'), `APP_VERSION=${newVersionStr}\nBUILD_NUMBER=${build}\n`);
}
