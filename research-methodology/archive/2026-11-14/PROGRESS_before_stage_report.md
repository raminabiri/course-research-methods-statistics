# PROGRESS — درس روش تحقیق پیشرفته

## Done
- 2026-10-26: README (opinion, architecture, syllabus), shared practice data (`data/`, `generate_data.R`, `load_survey.sps`).
- 2026-10-26: Chapters 2–12 written as FIRST DRAFTS (lesson/exercises/solutions + tested R code; SPSS untested — no SPSS here). User had asked for chapter 1 only → these are outside the requested scope; user not yet asked what to do with them (keep / delete / move).
- 2026-10-26: Chapter 1 REWRITTEN after user feedback (too many non-Persian words, explanations too short, philosophy of science too thin):
  - 6 lessons + 14 exercises + full solutions + README, in user's STYLE_GUIDE format (from /data/Education/bioinformatics_learning/STYLE_GUIDE.md): story, plain-language concept, ✋ try-it boxes with `<details>`, 3 common mistakes, lesson glossary, refs (paper / book / YouTube+Coursera+edX).
  - Philosophy of science is now a full phase: lessons 1–3 (science vs knowledge; Aristotle→Popper; Kuhn→Bayes, realism, values).
  - `_tools/` copied from bioinformatics course (persian_words.py, rtl_wrap.py); `glossary.md` created (user's §8 word table + conventions + 102 ch1 terms).
  - persian_words.py run: all manual hits fixed except accepted terms «تعریف عملیاتی», «عمل‌گرایی», «عملیات‌گرایی»; false positives «متوسط», «علمی باشد».
  - Files RTL-wrapped.

## Next steps
- Ask user to review chapter 1; then decide what to do with drafts of ch 2–12 (and empty 13–16).
- Re-check video/course URLs from a machine with internet (here: curl blocked, WebFetch blocked; verified only via web search results).
- Syllabus table in README still allots 1 session to ch1; it now needs ~2.
- When other chapters are rewritten: same STYLE_GUIDE format, glossary.md, run `_tools/persian_words.py` and `_tools/rtl_wrap.py`.

## Bugs / open issues
- No direct internet from shell (curl → 000) → `yt_search.sh` / `check_links.sh` cannot run here.
- SPSS syntax (ch 3–8) never executed; POWER/OMEGA syntax version-dependent.
- Old chapter 1 files deleted (copies in session scratchpad only).

## 2026-11-14 — Requirements update
- Added PROJECT_REQUIREMENTS.md: audience and biomedical scope, brief statistics, detailed sampling/sample size, offline desktop delivery, video links, and user-funded ChatGPT question entry points.
- Added STYLE_GUIDE.md with the author's new writing preferences; linked precedence from glossary.md. Existing lessons and the word checker are not yet migrated.
- Teaching roles, repository visibility, and licensing remain open. No application implementation or publication performed.
- Author clarified: retain established technical terms whenever the proposed Persian replacement changes scientific meaning; no further confirmation needed for these exceptions.
