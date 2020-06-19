local branch_re = "On branch \\(\\w\\+\\)"
local remote_re = "Your branch is \\(up to date with\\|ahead of\\|behind\\) '\\(.*\\)' \\?\\(by \\(\\d*\\) commit\\)\\?"
local change_re = "\\W*\\(.*\\):\\W*\\(.*\\)"

local function git_status()
  local output = vim.fn.systemlist("git status")
  local lineidx = 1

  local function parse_changes(list)
    while output[lineidx] ~= "" do
      local matches = vim.fn.matchlist(output[lineidx], change_re)
      local type = matches[2]
      local file = matches[3]
      table.insert(list, { type = type, file = file })
      lineidx = lineidx + 1
    end
  end

  local function skip_explanation()
    while string.find(output[lineidx], "\t") == nil do
      lineidx = lineidx + 1
    end
  end

  local result = {}

  result.staged_changes = {}
  result.unstaged_changes = {}
  result.untracked_files = {}
  result.ahead_by = 0
  result.behind_by = 0

  result.branch = vim.fn.matchlist(output[lineidx], branch_re)[2]
  lineidx = lineidx + 1

  local matches = vim.fn.matchlist(output[lineidx], remote_re)

  if matches[2] == "ahead of" then
    result.ahead_by = tonumber(matches[5])
  elseif matches[2] == "behind" then
    result.behind_by = tonumber(matches[5])
  end

  result.remote = matches[3]
  lineidx = lineidx + 1

  while output[lineidx] ~= "" do
    lineidx = lineidx + 1
  end

  lineidx = lineidx + 1

  if output[lineidx] == "Changes to be committed:" then
    skip_explanation()

    parse_changes(result.staged_changes)

    lineidx = lineidx + 1
  end

  if output[lineidx] == "Changes not staged for commit:" then
    skip_explanation()

    parse_changes(result.unstaged_changes)

    lineidx = lineidx + 1
  end

  if output[lineidx] == "Untracked files:" then
    skip_explanation()

    while output[lineidx] ~= "" do
      local file = string.sub(output[lineidx], 2)
      table.insert(result.untracked_files, file)
      lineidx = lineidx + 1
    end
  end

  return result
end

local function git_tree()
  local output = vim.fn.systemlist("git log --graph --pretty=oneline --abbrev-commit")
  return output
end

local function git_fetch()
  local output = vim.fn.systemlist("git fetch")
  return output
end

local function git_unpulled(branch)
  local output = vim.fn.systemlist("git log --oneline .." .. branch)
  return output
end

local function git_unmerged(branch)
  local output = vim.fn.systemlist("git log --oneline " .. branch .. "..")
  return output
end

return {
  status = git_status,
  fetch = git_fetch,
  unpulled = git_unpulled,
  unmerged = git_unmerged,
  tree = git_tree
}