#!/usr/bin/env node
/**
 * Export NevaDWH portal docs/pages → Markdown corpus for AnythingLLM workspace
 * "Neva Portal Helper" (user RAG).
 *
 * Usage (from repo root or this folder):
 *   node src/images/anything-llm/scripts/export-portal-rag.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '../../../..');
const NEVADWH = path.join(REPO_ROOT, 'src/NevaDWH/src');
const OUT_DIR = path.join(REPO_ROOT, 'src/images/anything-llm/rag/portal');
const OUT_DOCS = path.join(OUT_DIR, 'docs');
const OUT_PAGES = path.join(OUT_DIR, 'pages');

/** @type {{ file: string; route: string; outName: string }[]} */
const DOC_SOURCES = [
  { file: 'pages/docs/analytics.astro', route: '/docs/analytics/', outName: 'analytics.md' },
  { file: 'pages/docs/model-comparison.astro', route: '/docs/model-comparison/', outName: 'model-comparison.md' },
  { file: 'pages/docs/market-indices.astro', route: '/docs/market-indices/', outName: 'market-indices.md' },
  { file: 'pages/docs/ttm-roi.astro', route: '/docs/ttm-roi/', outName: 'ttm-roi.md' },
  { file: 'pages/docs/corporate-rag.astro', route: '/docs/corporate-rag/', outName: 'corporate-rag.md' },
  { file: 'pages/docs/metadata-sql.astro', route: '/docs/metadata-sql/', outName: 'metadata-sql.md' },
  { file: 'pages/docs/debug-sql.astro', route: '/docs/debug-sql/', outName: 'debug-sql.md' },
  { file: 'pages/docs/index.astro', route: '/docs/', outName: 'docs-index.md' },
];

/** @type {{ file: string; route: string; outName: string }[]} */
const PAGE_SOURCES = [
  { file: 'pages/about.astro', route: '/about/', outName: 'about.md' },
  { file: 'pages/nevaai.astro', route: '/nevaai/', outName: 'nevaai.md' },
  { file: 'pages/generator.astro', route: '/generator/', outName: 'generator.md' },
  { file: 'pages/debug-sql.astro', route: '/debug-sql/', outName: 'debug-sql-tool.md' },
];

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function readAstro(rel) {
  const full = path.join(NEVADWH, rel);
  if (!fs.existsSync(full)) {
    console.warn(`[skip] missing ${rel}`);
    return null;
  }
  return fs.readFileSync(full, 'utf8');
}

function pickConst(src, name) {
  const re = new RegExp(`const ${name}\\s*=\\s*['\`"]([^'\`"]+)['\`"]`);
  const m = src.match(re);
  if (m) return m[1];
  // multiline template / concat
  const re2 = new RegExp(
    `const ${name}\\s*=\\s*\\n\\s*['\`"]([^'\`"]+)['\`"]`,
  );
  const m2 = src.match(re2);
  return m2 ? m2[1] : '';
}

function stripScriptsAndStyles(html) {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '');
}

function extractTemplateBody(src) {
  // Drop YAML/JS frontmatter between ---
  const parts = src.split('---');
  let body = src;
  if (parts.length >= 3) {
    body = parts.slice(2).join('---');
  }
  body = stripScriptsAndStyles(body);
  // Prefer inner of DashboardLayout
  const open = body.search(/<DashboardLayout[\s\S]*?>/);
  if (open >= 0) {
    const afterOpen = body.indexOf('>', open) + 1;
    const close = body.lastIndexOf('</DashboardLayout>');
    if (close > afterOpen) body = body.slice(afterOpen, close);
  }
  // Drop huge XML sample in generator textarea
  body = body.replace(/<textarea[\s\S]*?<\/textarea>/gi, '\n\n_(поле ввода MetaData — содержимое примера опущено в RAG)_\n\n');
  body = body.replace(/<pre[\s\S]*?<\/pre>/gi, '\n\n');
  // Drop Astro expressions that are only icons / material symbols wrappers kept as text later
  return body;
}

function decodeEntities(s) {
  return s
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
}

function htmlishToMarkdown(html, consts = {}) {
  let s = html;
  for (const [k, v] of Object.entries(consts)) {
    if (!v) continue;
    s = s.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
  }
  // Astro expressions: {ident} — leave bare idents that remain
  s = s.replace(/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g, '$1');
  s = s.replace(/\{\s*[\s\S]*?\s*\}/g, ''); // drop complex JSX/Astro blocks

  s = s.replace(/<h1[^>]*>([\s\S]*?)<\/h1>/gi, (_, t) => `\n# ${innerText(t)}\n\n`);
  s = s.replace(/<h2[^>]*>([\s\S]*?)<\/h2>/gi, (_, t) => `\n## ${innerText(t)}\n\n`);
  s = s.replace(/<h3[^>]*>([\s\S]*?)<\/h3>/gi, (_, t) => `\n### ${innerText(t)}\n\n`);
  s = s.replace(/<hr\s*\/?>/gi, '\n\n---\n\n');
  s = s.replace(/<br\s*\/?>/gi, '\n');
  s = s.replace(/<li[^>]*>([\s\S]*?)<\/li>/gi, (_, t) => `- ${innerText(t).trim()}\n`);
  s = s.replace(/<\/?ul[^>]*>/gi, '\n');
  s = s.replace(/<\/?ol[^>]*>/gi, '\n');
  s = s.replace(/<a[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi, (_, href, t) => {
    const label = innerText(t).trim() || href;
    return `[${label}](${href})`;
  });
  s = s.replace(/<strong[^>]*>([\s\S]*?)<\/strong>/gi, (_, t) => `**${innerText(t)}**`);
  s = s.replace(/<b[^>]*>([\s\S]*?)<\/b>/gi, (_, t) => `**${innerText(t)}**`);
  s = s.replace(/<em[^>]*>([\s\S]*?)<\/em>/gi, (_, t) => `*${innerText(t)}*`);
  s = s.replace(/<code[^>]*>([\s\S]*?)<\/code>/gi, (_, t) => `\`${innerText(t)}\``);
  s = s.replace(/<p[^>]*>([\s\S]*?)<\/p>/gi, (_, t) => `\n${innerText(t).trim()}\n\n`);
  s = s.replace(/<figcaption[^>]*>([\s\S]*?)<\/figcaption>/gi, (_, t) => `\n_${innerText(t).trim()}_\n\n`);
  s = s.replace(/<[^>]+>/g, '');
  s = decodeEntities(s);
  s = s.replace(/[ \t]+\n/g, '\n');
  s = s.replace(/\n{3,}/g, '\n\n');
  return s.trim();
}

function innerText(fragment) {
  return decodeEntities(
    fragment
      .replace(/<[^>]+>/g, '')
      .replace(/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g, '$1')
      .replace(/\s+/g, ' ')
      .trim(),
  );
}

function buildDoc(route, title, description, markdown) {
  const fm = [
    '---',
    `workspace: portal-helper`,
    `route: ${route}`,
    `title: ${JSON.stringify(title)}`,
    description ? `description: ${JSON.stringify(description)}` : null,
    `source: nevadwh-astro`,
    '---',
    '',
    `# ${title}`,
    '',
    description ? `> ${description}` : null,
    description ? '' : null,
    `Канонический URL на портале: ${route}`,
    '',
    markdown,
    '',
  ]
    .filter((x) => x !== null)
    .join('\n');
  return fm;
}

function exportOne(srcMeta, outDir) {
  const raw = readAstro(srcMeta.file);
  if (!raw) return false;
  const title = pickConst(raw, 'pageTitle') || srcMeta.outName.replace(/\.md$/, '');
  const description = pickConst(raw, 'pageDescription');
  const body = extractTemplateBody(raw);
  let md = htmlishToMarkdown(body, { pageTitle: title, pageDescription: description });
  // Cap huge pages (e.g. residual junk)
  if (md.length > 80_000) {
    md = `${md.slice(0, 80_000)}\n\n…_(обрезано для RAG)_\n`;
  }
  const out = buildDoc(srcMeta.route, title, description, md);
  ensureDir(outDir);
  const outPath = path.join(outDir, srcMeta.outName);
  fs.writeFileSync(outPath, out, 'utf8');
  console.log(`[ok] ${srcMeta.route} → ${path.relative(REPO_ROOT, outPath)}`);
  return true;
}

function writeNavigationMap() {
  const navPath = path.join(OUT_DIR, '_curated', '01-navigation.md');
  ensureDir(path.dirname(navPath));
  const lines = [
    '---',
    'workspace: portal-helper',
    'title: "Карта портала NevaDWH"',
    'source: curated',
    '---',
    '',
    '# Карта портала NevaDWH',
    '',
    'Краткая навигация для ответов ассистента. Всегда давай пользователю прямую ссылку на раздел.',
    '',
    '## Основное',
    '',
    '- [Главная](/) — обзор платформы',
    '- [О платформе](/about/) — что уже есть и куда смотреть дальше',
    '- [Документация (каталог)](/docs/) — все статьи с описаниями',
    '',
    '## Инструменты',
    '',
    '- [MetaData → SQL](/generator/) — конвертация MetaDataObject 1С (XML/JSON) в SQL',
    '- Документация: [MetaData → SQL](/docs/metadata-sql/)',
    '- [Debug SQL](/debug-sql/) — audit-обёртки для процедур',
    '- Документация: [Debug SQL](/docs/debug-sql/)',
    '',
    '## Сервисы',
    '',
    '- [Генератор DWH](/app/) — личный кабинет, полная генерация слоёв',
    '- [Финансовый анализ](/finance/) — прогнозы и графики',
    '- [Форум](/forum/) — обсуждения и Technical / База данных',
    '- [Neva AI](/nevaai) — локальный AI-ассистент',
    '',
    '## Документация по разделам',
    '',
    '### Финансовый анализ',
    '- [Как пользоваться аналитикой](/docs/analytics/)',
    '- [Сравнение моделей](/docs/model-comparison/)',
    '- [Рыночные индексы](/docs/market-indices/)',
    '',
    '### Генератор DWH',
    '- [ROI: от недель к минутам](/docs/ttm-roi/)',
    '',
    '### Neva AI',
    '- [Корпоративный RAG](/docs/corporate-rag/)',
    '',
    '## Важные различия',
    '',
    '- **MetaData → SQL** (`/generator/`) — точечный предпросмотр по одному объекту 1С.',
    '- **Генератор DWH** (`/app/`) — полный ZIP/проект хранилища в личном кабинете.',
    '- **Debug SQL** — не генератор DWH; добавляет audit-логирование в текст процедуры.',
    '',
  ];
  fs.writeFileSync(navPath, lines.join('\n'), 'utf8');
  console.log(`[ok] curated nav → ${path.relative(REPO_ROOT, navPath)}`);
}

function writeManifest(files) {
  const manifest = {
    workspace: 'neva-portal-helper',
    workspaceSlugHint: 'neva-portal-helper',
    generatedAt: new Date().toISOString(),
    files,
  };
  const p = path.join(OUT_DIR, 'manifest.json');
  fs.writeFileSync(p, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
  console.log(`[ok] manifest → ${path.relative(REPO_ROOT, p)}`);
}

function main() {
  ensureDir(OUT_DOCS);
  ensureDir(OUT_PAGES);
  ensureDir(path.join(OUT_DIR, '_curated'));

  /** @type {string[]} */
  const files = [];

  for (const src of DOC_SOURCES) {
    if (exportOne(src, OUT_DOCS)) {
      files.push(`docs/${src.outName}`);
    }
  }
  for (const src of PAGE_SOURCES) {
    if (exportOne(src, OUT_PAGES)) {
      files.push(`pages/${src.outName}`);
    }
  }

  writeNavigationMap();
  files.push('_curated/01-navigation.md');
  files.push('_curated/00-portal-overview.md');
  files.push('_curated/system-prompt.txt');

  writeManifest(files);
  console.log(`\nPortal RAG corpus ready: ${OUT_DIR}`);
  console.log('Next: upload via scripts/upload-portal-rag.ps1 (AnythingLLM API key required).');
}

main();
