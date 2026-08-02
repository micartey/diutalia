#!/usr/bin/env node

/**
 * Update Registry Script
 *
 * Scans all theme directories for JSON color scheme files and generates
 * an updated registry.json with theme metadata and color palettes.
 */

const fs = require('fs');
const path = require('path');

const REGISTRY_VERSION = 1;
const ROOT_DIR = path.join(__dirname, '..', '..');
const REGISTRY_PATH = path.join(ROOT_DIR, 'registry.json');

/**
 * Check if a directory contains a valid theme (has a .json file)
 */
function isThemeDirectory(dirPath) {
  try {
    const items = fs.readdirSync(dirPath);
    return items.some(item => item.toLowerCase().endsWith('.json'));
  } catch {
    return false;
  }
}

/**
 * Read and parse a theme's JSON file
 */
function readThemeJson(dirPath) {
  try {
    const items = fs.readdirSync(dirPath);
    const jsonFile = items.find(item => item.toLowerCase().endsWith('.json'));
    if (!jsonFile) return null;

    const jsonPath = path.join(dirPath, jsonFile);
    const content = fs.readFileSync(jsonPath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    console.error(`Error reading theme from ${dirPath}:`, error.message);
    return null;
  }
}

/**
 * Extract all color values from a variant (dark or light)
 */
function extractColors(variant) {
  if (!variant || typeof variant !== 'object') return {};

  const colorKeys = [
    'mPrimary', 'mOnPrimary',
    'mSecondary', 'mOnSecondary',
    'mTertiary', 'mOnTertiary',
    'mError', 'mOnError',
    'mSurface', 'mOnSurface',
    'mSurfaceVariant', 'mOnSurfaceVariant',
    'mOutline', 'mShadow',
    'mHover', 'mOnHover'
  ];

  const result = {};
  for (const key of colorKeys) {
    if (variant[key]) {
      result[key] = variant[key];
    }
  }
  return result;
}

/**
 * Extract registry entry from a theme
 */
function extractRegistryEntry(themeJson, dirName) {
  const darkVariant = themeJson.dark || themeJson;
  const lightVariant = themeJson.light || themeJson;

  return {
    name: dirName,
    path: dirName,
    dark: extractColors(darkVariant),
    light: extractColors(lightVariant)
  };
}

/**
 * Scan the repository for theme directories
 */
function scanThemes() {
  const themes = [];

  const items = fs.readdirSync(ROOT_DIR, { withFileTypes: true });

  for (const item of items) {
    if (!item.isDirectory() || item.name.startsWith('.') || item.name === 'node_modules') {
      continue;
    }

    const dirPath = path.join(ROOT_DIR, item.name);

    if (isThemeDirectory(dirPath)) {
      const themeJson = readThemeJson(dirPath);
      if (themeJson) {
        const registryEntry = extractRegistryEntry(themeJson, item.name);
        themes.push(registryEntry);
        console.log(`- Found theme: ${item.name}`);
      }
    }
  }

  return themes;
}

/**
 * Generate the registry.json content
 */
function generateRegistry(themes) {
  themes.sort((a, b) => a.name.localeCompare(b.name));

  return {
    version: REGISTRY_VERSION,
    themes: themes
  };
}

/**
 * Write the registry to disk
 */
function writeRegistry(registry) {
  const content = JSON.stringify(registry, null, 2) + '\n';
  fs.writeFileSync(REGISTRY_PATH, content, 'utf8');
}

/**
 * Main execution
 */
function main() {
  console.log('Scanning for themes...');

  const themes = scanThemes();
  if (themes.length === 0) {
    console.warn('No themes found. Registry will be empty.');
  }

  const registry = generateRegistry(themes);
  writeRegistry(registry);

  console.log(`Registry updated successfully at ${REGISTRY_PATH}`);
  console.log(`Total Themes: ${registry.themes.length}`);
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error('Error updating registry:', error);
    process.exit(1);
  }
}

module.exports = { scanThemes, generateRegistry, extractRegistryEntry };
