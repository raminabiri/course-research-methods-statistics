#!/usr/bin/env python3
"""Build bottom-of-page links for authored course Markdown pages.

Navigation is kept in curriculum/navigation.json for read-only validation.
Legacy drafts outside authored modules and archives are left unchanged.
"""
import json
import os
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
START = '<!-- COURSE_NAV_START -->'
END = '<!-- COURSE_NAV_END -->'
links = {}

def register(path, previous, following, home='README.md'):
    links[str(path)] = {'previous':str(previous),'next':str(following),'home':str(home)}

def title(path):
    text=(ROOT/path).read_text(encoding='utf-8')
    hit=re.search(r'^# (.+)$',text,re.M)
    return hit.group(1).strip() if hit else Path(path).stem

def relative(source,target):
    return Path(os.path.relpath(ROOT/target,(ROOT/source).parent)).as_posix()

register('README.md','curriculum/README.md','01_foundations/README.md')
register('curriculum/README.md','README.md','01_foundations/README.md')
for manifest_path in sorted(ROOT.glob('[0-9][0-9]_*/manifest.json')):
    module=json.loads(manifest_path.read_text())
    folder=manifest_path.parent.relative_to(ROOT).as_posix()
    overview=f'{folder}/README.md'
    solution_home=f'solutions/{folder}/README.md'
    resources=[f'{folder}/resources/{name}.md' for name in (
        ['claim_audit','question_workbook','variables_workbook','glossary','references','videos']
        if module['module']=='M01' else
        ['protocol_template','sampling_data_dictionary','references','videos'])]
    sequence=[overview]+[r['path'] for r in module['lessons']]
    sequence += [r['exercises_path'] for r in module['lessons']]
    sequence += [solution_home]+[r['solutions_path'] for r in module['lessons']]+resources
    for index,path in enumerate(sequence):
        register(path,sequence[index-1] if index else 'curriculum/README.md',
                 sequence[index+1] if index+1<len(sequence) else 'curriculum/README.md',overview)
    for row in module['lessons']:
        row['navigation']={k:links[row['path']][k] for k in ['previous','next']}
    manifest_path.write_text(json.dumps(module,ensure_ascii=False,indent=2)+'\n')
    # Old entry points still exist on GitHub; both footer links work there too.
    for path in manifest_path.parent.glob('*.md'):
        local=path.relative_to(ROOT).as_posix()
        if local in links:
            continue
        text=path.read_text()
        matches=re.findall(r'\]\(([^)]+)\)',text)
        target=overview
        for match in matches:
            resolved=(path.parent/match).resolve()
            if resolved.is_file() and ('lessons' in resolved.parts or 'solutions' in resolved.parts):
                target=resolved.relative_to(ROOT).as_posix()
                break
        register(local,overview,target,overview)
    for path in manifest_path.parent.rglob('*.md'):
        local=path.relative_to(ROOT).as_posix()
        if local not in links:
            register(local,overview,'curriculum/README.md',overview)

register('references/README.md','README.md','01_foundations/resources/references.md')
for path in sorted((ROOT/'reports').glob('*.md')):
    register(path.relative_to(ROOT),'README.md','curriculum/README.md')
for name in ['STYLE_GUIDE.md','PROJECT_REQUIREMENTS.md','PROGRESS.md','glossary.md']:
    register(name,'README.md','curriculum/README.md')

for path,item in sorted(links.items()):
    file=ROOT/path;text=file.read_text(encoding='utf-8')
    text=re.sub(r'\n*'+re.escape(START)+r'.*?'+re.escape(END)+r'\n*','\n',text,flags=re.S)
    # Remove old partial lesson navigation so that only the final footer remains.
    text=re.sub(r'^\[درس (?:پیشین|بعدی)\]\([^\n]+\)\s*\n','',text,flags=re.M)
    if text.lstrip().startswith('<div dir="rtl">') and text.count('</div>') == 1:
        text=text.replace('\n</div>', '').rstrip()+'\n\n</div>\n'
    footer='\n\n'+START+'\n\n---\n\n'
    footer+=f'[صفحهٔ پیشین: {title(item["previous"])}]({relative(path,item["previous"])})'
    footer+=f' · [فهرست]({relative(path,item["home"])}) · '
    footer+=f'[صفحهٔ پسین: {title(item["next"])}]({relative(path,item["next"])})'
    footer+='\n\n'+END+'\n'
    closing=re.search(r'\n</div>\s*$',text)
    if closing:
        text=text[:closing.start()].rstrip()+footer+'\n</div>\n'
    else:
        text=text.rstrip()+footer
    file.write_text(text,encoding='utf-8')

(ROOT/'curriculum/navigation.json').write_text(json.dumps({'version':1,'date':'2026-11-15','pages':links},ensure_ascii=False,indent=2)+'\n')
print(f'Built previous/next footers on {len(links)} authored Markdown pages.')
