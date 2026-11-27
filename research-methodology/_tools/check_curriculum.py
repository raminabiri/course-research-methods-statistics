#!/usr/bin/env python3
"""Read-only checks for curriculum metadata and every authored module.

Run from any directory. Legacy drafts and archives are outside the writing scan.
"""
import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit, parse_qs

ROOT = Path(__file__).resolve().parents[1]
errors = []

def fail(message):
    errors.append(message)

def load(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))

curriculum = load('curriculum/manifest.json')
all_ids = [row['id'] for row in curriculum['lessons']]
if len(all_ids) != len(set(all_ids)):
    fail('Duplicate curriculum lesson IDs')
planned = {row['id']: row for row in curriculum['lessons']}
module_ids = {row['module'] for row in curriculum['lessons']}
for row in curriculum['lessons']:
    if set(row['levels']) != {'beginner', 'intermediate', 'advanced'}:
        fail(f'{row["id"]}: missing learning level')
    if any(p not in module_ids for p in row['prerequisites']):
        fail(f'{row["id"]}: unknown prerequisite')
    for level, code in [('beginner', 'B'), ('intermediate', 'I'), ('advanced', 'A')]:
        exercise_ids = row['exercise_ids'].get(level, [])
        expected = [f'{row["id"]}-{code}{j:02}'
                    for j in range(1, len(exercise_ids) + 1)]
        if exercise_ids != expected:
            fail(f'{row["id"]}: invalid exercise ID allocation')

dependencies = {}
for row in curriculum['lessons']:
    if row['module'] in dependencies and dependencies[row['module']] != row['prerequisites']:
        fail(f'{row["module"]}: inconsistent module prerequisites')
    dependencies[row['module']] = row['prerequisites']
visited, active = set(), set()
def visit(key):
    if key in active:
        fail(f'Prerequisite cycle at {key}')
        return
    if key in visited:
        return
    active.add(key)
    for other in dependencies[key]:
        if other in dependencies:
            visit(other)
    active.remove(key)
    visited.add(key)
for key in dependencies:
    visit(key)

paths = [ROOT/'curriculum/README.md', ROOT/'README.md', ROOT/'references/README.md']
paths += sorted((ROOT/'reports').glob('*.md'))
lesson_count = exercise_count = 0
written_ids = set()
module_summaries = []
manifest_paths = sorted(ROOT.glob('[0-9][0-9]_*/manifest.json'))
if not manifest_paths:
    fail('No authored module manifests found')
for manifest_path in manifest_paths:
    module = load(manifest_path)
    catalog = load(manifest_path.parent/'resources/catalog.json')
    name = module['module']
    planned_ids = {r['id'] for r in curriculum['lessons'] if r['module'] == name}
    actual_ids = [r['id'] for r in module['lessons']]
    if len(actual_ids) != len(set(actual_ids)) or set(actual_ids) != planned_ids:
        fail(f'{name}: authored and planned lesson IDs do not match')
    for row in module['lessons']:
        if row['id'] in written_ids:
            fail(f'{row["id"]}: duplicate authored lesson')
        written_ids.add(row['id'])
        target = planned.get(row['id'])
        planned_exercise_ids = (
            [exercise_id
             for level in ('beginner', 'intermediate', 'advanced')
             for exercise_id in target['exercise_ids'][level]]
            if target is not None else []
        )
        if row['exercise_ids'] != planned_exercise_ids:
            fail(f'{row["id"]}: exercise IDs differ from curriculum plan')
        expected = row['exercise_ids']
        missing = False
        required_paths = ['path']
        if expected:
            required_paths.extend(['exercises_path', 'solutions_path'])
        for key in required_paths:
            if key not in row or not (ROOT / row[key]).is_file():
                fail(f'{row["id"]}: missing {key}')
                missing = True
        if missing:
            continue
        if expected and not row['solutions_path'].startswith(f'solutions/{manifest_path.parent.name}/'):
            fail(f'{row["id"]}: solutions must be in the separate solutions tree')
        lesson = (ROOT / row['path']).read_text()
        exercises = (ROOT / row['exercises_path']).read_text() if expected else ''
        answers = (ROOT / row['solutions_path']).read_text() if expected else ''
        if set(row['levels']) != {'beginner', 'intermediate', 'advanced'}:
            fail(f'{row["id"]}: missing authored level')
        for heading in ('## سطح مقدماتی', '## سطح متوسط', '## سطح پیشرفته',
                        '## واژه‌نامه', '## منابع و مطالعهٔ بیشتر', '## فیلم‌های آموزشی',
                        '## 💬 پرسش از ChatGPT'):
            if heading not in lesson:
                fail(f'{row["id"]}: missing {heading}')
        if row.get('teaching_revision'):
            for teaching_heading in ('## مسیر پیشنهادی خواندن','### مکث و بررسی برداشت'):
                if teaching_heading not in lesson:
                    fail(f'{row["id"]}: missing teaching section {teaching_heading}')
            if '<summary>بازخورد کوتاه را بخوانید</summary>' not in lesson:
                fail(f'{row["id"]}: missing formative feedback')
        for text, label in ((exercises, 'exercises'), (answers, 'solutions')):
            actual = re.findall(r'^### (M\d{2}-L\d{2}-[BIA]\d{2})$', text, re.M)
            if actual != expected:
                fail(f'{row["id"]}: {label} IDs do not match')
        if exercises.count('💬 **پرسش از ChatGPT:**') != len(expected):
            fail(f'{row["id"]}: exercise prompt count does not match exercise IDs')
        if answers.count('**معیار ارزیابی:**') != len(expected):
            fail(f'{row["id"]}: grading criteria count does not match exercise IDs')
        for category, minimum in [('videos', 2), ('references', 3)]:
            ids = row[category]
            if len(ids) < minimum or len(ids) != len(set(ids)):
                fail(f'{row["id"]}: insufficient or duplicate {category}')
            for key in ids:
                record = catalog[category].get(key)
                if record is None:
                    fail(f'{row["id"]}: missing {category} record {key}')
                elif urlsplit(record['url']).scheme not in ('http', 'https'):
                    fail(f'{row["id"]}: invalid URL for {key}')
                elif record['url'] not in lesson:
                    fail(f'{row["id"]}: catalog item {key} not linked in lesson')
        youtube_ids = []
        for video_id in row['videos']:
            record = catalog['videos'].get(video_id)
            if record is None:
                continue
            url = urlsplit(record['url'])
            if url.hostname in ('www.youtube.com', 'youtube.com') and url.path == '/watch':
                item_id = parse_qs(url.query).get('v', [''])[0]
                if re.fullmatch(r'[A-Za-z0-9_-]{11}', item_id):
                    youtube_ids.append(item_id)
        if len(set(youtube_ids)) < 2:
            fail(f'{row["id"]}: at least two distinct direct YouTube video URLs required')
        if target is None or target['status'] != 'written_for_review':
            fail(f'{row["id"]}: curriculum status mismatch')
        else:
            path_keys = ['path']
            if expected:
                path_keys.extend(['exercises_path', 'solutions_path'])
            if any(target.get(key) != row.get(key) for key in path_keys):
                fail(f'{row["id"]}: curriculum path mismatch')
        lesson_count += 1
        exercise_count += len(expected)
    paths += sorted(manifest_path.parent.rglob('*.md'))
    paths += sorted((ROOT/'solutions'/manifest_path.parent.name).glob('*.md'))
    module_exercise_count = sum(len(row['exercise_ids']) for row in module['lessons'])
    module_summaries.append(f'{name}: {len(actual_ids)} lessons / {module_exercise_count} exercises')

for row in curriculum['lessons']:
    if row['status'] == 'written_for_review' and row['id'] not in written_ids:
        fail(f'{row["id"]}: written status without authored module record')

# Established technical terms such as experimental unit and independent variable
# are permitted by the author's explicit exception in STYLE_GUIDE.md.
words = r'کلمه|عدم|عملکرد|استفاده|مشاهده|قواعد|دستورالعمل|رایج|اصلاح|انتها|مثال'
style = re.compile(r'(?<![\w\u200c])(?:'+words+r')(?![\w\u200c])'
                   r'|(?<![\w\u200c])می[\u200c ](?:باشد|گردد)|برای مثال|[\u064b-\u064d]'
                   r'|(?<![\w\u200c])ممکن است(?![\w\u200c])'
                   r'|می‌تواند این[\u200c ]گونه باشد')
protected = re.compile(r'```.*?```|~~~.*?~~~|`[^`\n]*`|https?://[^\s)]+', re.S)
link_count = 0
paths = sorted(set(paths))
for path in paths:
    text = path.read_text(encoding='utf-8')
    relative = path.relative_to(ROOT)
    if (relative.parts[0] == '01_foundations'
            or relative.parts[:2] == ('solutions', '01_foundations')):
        if text.count('<div dir="rtl">') != 1 or text.count('</div>') != 1:
            fail(f'{relative}: expected one complete RTL wrapper')
    prose = protected.sub(lambda m: '\n' * m.group(0).count('\n'), text)
    for n, line in enumerate(prose.splitlines(), 1):
        if style.search(line):
            fail(f'{path.relative_to(ROOT)}:{n}: writing preference: {line[:130]}')
    for match in re.finditer(r'\[[^\]\n]*\]\(([^)\n]+)\)', text):
        target = match.group(1).strip().strip('<>')
        if urlsplit(target).scheme or target.startswith('#'):
            continue
        destination = unquote(target.split('#', 1)[0])
        if destination and not (path.parent / destination).resolve().exists():
            fail(f'{path.relative_to(ROOT)}: broken link {target}')
        link_count += bool(destination)
# Footers must be the final visible block and match the stored reading path.
nav = load('curriculum/navigation.json')['pages']
for local, item in nav.items():
    path = ROOT / local
    if not path.is_file():
        fail(f'{local}: navigation source is missing')
        continue
    text = path.read_text()
    match = re.search(r'<!-- COURSE_NAV_START -->(.*?)<!-- COURSE_NAV_END -->',text,re.S)
    if match is None or text.count('<!-- COURSE_NAV_START -->') != 1:
        fail(f'{local}: exactly one final navigation footer is required')
        continue
    tail=text[match.end():].replace('</div>','').strip()
    if tail:
        fail(f'{local}: content follows navigation footer')
    for direction,label in [('previous','صفحهٔ پیشین'),('next','صفحهٔ پسین')]:
        target=ROOT/item[direction]
        if not target.is_file() or target.resolve()==path.resolve():
            fail(f'{local}: invalid {direction} page')
        link=re.search(r'\['+label+r': [^\]]+\]\(([^)]+)\)',match.group(1))
        if link is None or (path.parent/link.group(1)).resolve()!=target.resolve():
            fail(f'{local}: {direction} footer does not match reading path')
for manifest_path in manifest_paths:
    module=load(manifest_path)
    for row in module['lessons']:
        if row.get('navigation') != {k:nav.get(row['path'],{}).get(k) for k in ['previous','next']}:
            fail(f'{row["id"]}: lesson navigation metadata mismatch')
if errors:
    print('\n'.join(errors))
    sys.exit(1)
print(f'PASS: {len(module_ids)} modules, {len(all_ids)} planned lessons; '
      f'{lesson_count} authored lessons and {exercise_count} matched exercises/answers.')
print('PASS: ' + '; '.join(module_summaries))
print(f'PASS: prerequisite graph, metadata, levels, grading, prompts, catalogs; '
      f'{link_count} local links; writing scan on {len(paths)} Markdown files.')
print(f'PASS: previous/next links on {len(nav)} pages, final placement and stored targets.')
print('Scope: authored curriculum content only. No video playback, desktop UI, '
      'SPSS execution, or human scientific review is implied.')
