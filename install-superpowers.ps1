# 🦸 GEMINI CLI SUPERPOWERS INSTALLER for Windows
# ==============================================================================
# "Radically Simple" Adapter for Google Gemini CLI
#
# 1. Clones obra/superpowers to $HOME/.cache/superpowers
# 2. Generates native .toml slash commands in $HOME/.gemini/commands/
# 3. Injects the "Loop of Autonomy" protocol into GEMINI.md (local or global)
# ==============================================================================

$ErrorActionPreference = "Stop"

# --- Configuration ---
$REPO_URL = "https://github.com/obra/superpowers"
$CACHE_DIR = Join-Path $HOME ".cache\superpowers"
$GEMINI_ROOT = Join-Path $HOME ".gemini"

# Default to global installation
$INSTALL_GLOBAL = $true
$WORKSPACE_ROOT = Get-Location

if ($INSTALL_GLOBAL) {
    $GEMINI_MD_INSTALL_PATH = Join-Path $GEMINI_ROOT "GEMINI.md"
    $GEMINI_SKILLS_BASE_DIR = Join-Path $GEMINI_ROOT ".superpowers\skills"
    $COMMANDS_DIR = Join-Path $GEMINI_ROOT "commands"
    Write-Host "🌍 Installing superpowers globally to $HOME..." -ForegroundColor Cyan
} else {
    # Workspace-local installation
    $GEMINI_LOCAL = Join-Path $WORKSPACE_ROOT ".gemini"
    if (-not (Test-Path $GEMINI_LOCAL)) {
        New-Item -ItemType Directory -Path $GEMINI_LOCAL | Out-Null
    }
    $GEMINI_MD_INSTALL_PATH = Join-Path $GEMINI_LOCAL "GEMINI.md"
    $GEMINI_SKILLS_BASE_DIR = Join-Path $GEMINI_LOCAL ".superpowers\skills"
    $COMMANDS_DIR = Join-Path $GEMINI_LOCAL "commands"
    Write-Host "📁 Installing superpowers workspace-locally to $WORKSPACE_ROOT..." -ForegroundColor Cyan
}

$CONTEXT_FILE = $GEMINI_MD_INSTALL_PATH

# --- Mappings: SkillDir:CommandName:Description ---
$SKILLS = @(
    "writing-plans:plan:Create a detailed implementation plan",
    "executing-plans:execute:Execute an implementation plan task-by-task",
    "brainstorming:brainstorm:Refine ideas through Socratic dialogue",
    "test-driven-development:tdd:Implement code using strict Red-Green-Refactor",
    "systematic-debugging:investigate:Perform systematic root-cause analysis",
    "verification-before-completion:verify:Verify fixes before signing off",
    "using-git-worktrees:worktree:Create isolated git worktree for features",
    "finishing-a-development-branch:finish:Merge, PR, or discard current branch",
    "requesting-code-review:review:Request a self-correction code review",
    "receiving-code-review:receive:Respond to code review feedback",
    "subagent-driven-development:subagent:Dispatch subagents for rapid development",
    "dispatching-parallel-agents:dispatch:Run parallel subagent workflows",
    "writing-skills:newskill:Create a new Superpowers skill",
    "using-superpowers:superpowers:Learn about available Superpowers"
)

Write-Host "`n🦸 Gemini CLI Superpowers Installer" -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow

# 1. Setup Cache
Write-Host ""
if (Test-Path $CACHE_DIR) {
    Write-Host "🔄 Updating Superpowers cache..." -ForegroundColor Green
    git -C $CACHE_DIR pull -q
} else {
    Write-Host "⬇️  Cloning Superpowers to $CACHE_DIR..." -ForegroundColor Green
    $cacheParent = Split-Path $CACHE_DIR
    if (-not (Test-Path $cacheParent)) {
        New-Item -ItemType Directory -Path $cacheParent -Force | Out-Null
    }
    git clone -q $REPO_URL $CACHE_DIR
}

# 1b. Setup Skills in Gemini config directory
Write-Host "📦 Installing skills to $GEMINI_SKILLS_BASE_DIR..." -ForegroundColor Green
if (-not (Test-Path $GEMINI_SKILLS_BASE_DIR)) {
    New-Item -ItemType Directory -Path $GEMINI_SKILLS_BASE_DIR -Force | Out-Null
}

$cacheSkillsPath = Join-Path $CACHE_DIR "skills"
Get-ChildItem -Path $cacheSkillsPath -Directory | ForEach-Object {
    $dest = Join-Path $GEMINI_SKILLS_BASE_DIR $_.Name
    if (Test-Path $dest) {
        Remove-Item -Path $dest -Recurse -Force
    }
    Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
}

# 2. Generate Slash Commands
Write-Host "🛠️  Generating Slash Commands..." -ForegroundColor Green
if (-not (Test-Path $COMMANDS_DIR)) {
    New-Item -ItemType Directory -Path $COMMANDS_DIR -Force | Out-Null
}

$count = 0
foreach ($entry in $SKILLS) {
    $parts = $entry -split ":"
    $skill_dir = $parts[0]
    $cmd_name = $parts[1]
    $desc = $parts[2]

    if ($INSTALL_GLOBAL) {
        $skill_file = Join-Path $GEMINI_SKILLS_BASE_DIR "$skill_dir\SKILL.md"
    } else {
        $skill_file = ".gemini/.superpowers/skills/$skill_dir/SKILL.md"
    }
    
    $check_path = Join-Path $GEMINI_SKILLS_BASE_DIR "$skill_dir\SKILL.md"
    $toml_file = Join-Path $COMMANDS_DIR "$cmd_name.toml"

    if (Test-Path $check_path) {
        # Normalize paths for Gemini CLI (using forward slashes)
        $skill_file_normalized = $skill_file.Replace('\', '/')
        $content = @"
description = "$desc"
prompt = """
@{$skill_file_normalized}

Task: {{args}}
"""
"@
        Set-Content -Path $toml_file -Value $content -Encoding utf8
        Write-Host "   ✓ /$cmd_name -> $skill_dir"
        $count++
    } else {
        Write-Host "   ⚠️  Missing skill: $skill_dir" -ForegroundColor Yellow
    }
}

# 3. Inject Global Context
Write-Host "`n📝 Injecting protocol into $CONTEXT_FILE..." -ForegroundColor Green
$MARKER = "<!-- SUPERPOWERS-PROTOCOL -->"

# Detect skill-creator path
$SKILL_CREATOR_PATH = "C:\Users\Ujwal\AppData\Roaming\npm\node_modules\@google\gemini-cli\bundle\builtin\skill-creator\SKILL.md"
if (-not (Test-Path $SKILL_CREATOR_PATH)) {
    # Fallback/Guess if path is different (though system prompt confirms this one)
    $SKILL_CREATOR_PATH = "SKILL_CREATOR_PATH_NOT_FOUND"
}

$PROTOCOL_CONTENT = @"
$MARKER
# SUPERPOWERS PROTOCOL
You are an autonomous coding agent operating on a strict "Loop of Autonomy."

## CORE DIRECTIVE
1. **PERCEIVE**: Read \`plan.md\` if it exists. Do not act without checking the plan.
2. **ACT**: Execute the next unchecked step in the plan.
3. **UPDATE**: Check off the step in \`plan.md\` when verified.
4. **LOOP**: If the task is large, do not stop. Continue to the next step.

## SKILLS (Slash Commands)
You have access to native slash commands that enforce best practices.
- Use \`/plan\` (writing-plans) to create detailed plans.
- Use \`/tdd\` (test-driven-development) to write code. NEVER write code without a failing test.
- Use \`/investigate\` (systematic-debugging) when tests fail.
- Use \`/verify\` (verification-before-completion) to double-check work.

If you are stuck, write a theory in \`scratchpad.md\`.

## Available Agent Skills

You have access to the following specialized skills. To activate a skill and receive its detailed instructions, you can call the \`activate_skill\` tool with the skill's name.

<available_skills>
  <skill>
    <name>skill-creator</name>
    <description>Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Gemini CLI's capabilities with specialized knowledge, workflows, or tool integrations.</description>
    <location>$SKILL_CREATOR_PATH</location>
  </skill>
  <skill>
    <name>writing-plans</name>
    <description>Use when you have a spec or requirements for a multi-step task, before touching code. Create comprehensive implementation plans, documenting everything an engineer needs to know.</description>
    <instructions>
# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** \`docs/plans/YYYY-MM-DD-<feature-name>.md\`

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

\`\`\`markdown
# [Feature Name] Implementation Plan

> **For Gemini:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
\`\`\`

## Task Structure

\`\`\`markdown
### Task N: [Component Name]

**Files:**
- Create: \`exact/path/to/file.py\`
- Modify: \`exact/path/to/existing.py:123-145\`
- Test: \`tests/exact/path/to/test.py\`

**Step 1: Write the failing test**

\`\`\`python
def test_specific_behavior():
    result = function(input)
    assert result == expected
\`\`\`

**Step 2: Run test to verify it fails**

Run: \`pytest tests/path/test.py::test_name -v\`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

\`\`\`python
def function(input):
    return expected
\`\`\`

**Step 4: Run test to verify it passes**

Run: \`pytest tests/path/test.py::test_name -v\`
Expected: PASS

**Step 5: Commit**

\`\`\`bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
\`\`\`
\`\`\`

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to \`docs/plans/<filename>>.md\`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses superpowers:executing-plans
    </instructions>
  </skill>
</available_skills>
$MARKER
"@

if (Test-Path $CONTEXT_FILE) {
    $existingContent = Get-Content -Raw -Path $CONTEXT_FILE
    if ($existingContent -match [regex]::Escape($MARKER)) {
        $pattern = "(?s)" + [regex]::Escape($MARKER) + ".*?" + [regex]::Escape($MARKER)
        $newContent = [regex]::Replace($existingContent, $pattern, $PROTOCOL_CONTENT.Replace('$', '$$'))
        Set-Content -Path $CONTEXT_FILE -Value $newContent -Encoding utf8
        Write-Host "   ✓ Updated existing protocol definition at $CONTEXT_FILE"
    } else {
        Add-Content -Path $CONTEXT_FILE -Value "`n$PROTOCOL_CONTENT" -Encoding utf8
        Write-Host "   ✓ Appended protocol to context file at $CONTEXT_FILE"
    }
} else {
    Set-Content -Path $CONTEXT_FILE -Value $PROTOCOL_CONTENT -Encoding utf8
    Write-Host "   ✓ Created protocol context file at $CONTEXT_FILE"
}

Write-Host "`n✅ Installation Complete ($count commands installed)" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Restart Gemini CLI, then try:"
Write-Host "  /plan Build a simple hello world script"
