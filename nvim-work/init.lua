-- Plugin-free Neovim config for the work devcontainer (Neovim 0.8.0, RHEL8).
-- One file, no plugins, nothing to install. Keys follow LazyVim where Neovim
-- can do the same thing natively, so home and work habits match.
--
-- Sections: options · keys · explorer (netrw) · picker · grep/quickfix ·
-- LSP · commenting · terminal · sessions · status/tab line

local map = vim.keymap.set
local fn, api = vim.fn, vim.api
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

---------------------------------------------------------------------------
-- Options
---------------------------------------------------------------------------
local o = vim.opt
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.scrolloff = 4
o.wrap = false
o.mouse = "a"
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true
o.splitright = true
o.splitbelow = true
o.undofile = true
o.updatetime = 300
o.timeoutlen = 500
o.termguicolors = true
o.laststatus = 3
o.showmode = false
o.completeopt = { "menu", "menuone", "noselect" }
o.path = { ".", "**" }
o.wildignore:append({ "*/.git/*", "*/node_modules/*" })
o.wildmode = { "longest:full", "full" }
o.list = true
o.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
o.sessionoptions = { "buffers", "curdir", "folds", "help", "tabpages", "winsize" }
if fn.has("clipboard") == 1 then o.clipboard = "unnamedplus" end
o.fillchars = { eob = " " } -- no ~ after the end of a file
-- Colours: see "Theme" near the end.

---------------------------------------------------------------------------
-- Keys: general
---------------------------------------------------------------------------
map("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>")
map({ "n", "i", "x" }, "<C-s>", "<cmd>w<cr><Esc>", { desc = "Save" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Move lines (Alt-j / Alt-k)
map("n", "<M-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<M-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("i", "<M-j>", "<Esc><cmd>m .+1<cr>==gi")
map("i", "<M-k>", "<Esc><cmd>m .-2<cr>==gi")
map("x", "<M-j>", ":m '>+1<cr>gv=gv", { desc = "Move lines down" })
map("x", "<M-k>", ":m '<-2<cr>gv=gv", { desc = "Move lines up" })

-- Buffers
local function listed_buffers()
  return vim.tbl_filter(function(b) return fn.buflisted(b) == 1 end, api.nvim_list_bufs())
end
local function delete_buffer()
  local cur = api.nvim_get_current_buf()
  if vim.bo[cur].modified then return vim.notify("Unsaved changes: save first (Ctrl-s)", vim.log.levels.WARN) end
  if #listed_buffers() > 1 then vim.cmd.bprevious() else vim.cmd.enew() end
  pcall(vim.cmd, "bdelete " .. cur)
end
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bb", "<C-^>", { desc = "Alternate buffer" })
map("n", "<leader>`", "<C-^>", { desc = "Alternate buffer" })
map("n", "<leader>bd", delete_buffer, { desc = "Delete buffer" })
map("n", "<leader>bo", function()
  local cur = api.nvim_get_current_buf()
  for _, b in ipairs(listed_buffers()) do
    if b ~= cur and not vim.bo[b].modified then pcall(vim.cmd, "bdelete " .. b) end
  end
end, { desc = "Delete other buffers" })

-- Windows. Ctrl-h/j/k/l also crosses into tmux panes (no plugin needed).
local function navigate(dir)
  local win = api.nvim_get_current_win()
  vim.cmd("wincmd " .. dir)
  if api.nvim_get_current_win() == win and vim.env.TMUX then
    fn.system({ "tmux", "select-pane", "-" .. ({ h = "L", j = "D", k = "U", l = "R" })[dir] })
  end
end
for _, d in ipairs({ "h", "j", "k", "l" }) do
  map("n", "<C-" .. d .. ">", function() navigate(d) end, { desc = "Go to window/pane " .. d })
end
map("n", "<leader>|", "<C-w>v", { desc = "Split right" })
map("n", "<leader>-", "<C-w>s", { desc = "Split below" })
map("n", "<leader>wv", "<C-w>v", { desc = "Split right" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split below" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Only this window" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equal window sizes" })
map("n", "<leader>wx", "<C-w>x", { desc = "Swap windows" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>")
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>")
map("n", "<C-Up>", "<cmd>resize +2<cr>")
map("n", "<C-Down>", "<cmd>resize -2<cr>")

-- Lists of places (built-in commands, LazyVim keys)
map("n", "<leader>sj", "<cmd>jumps<cr>", { desc = "Jumplist" })
map("n", "<leader>sm", "<cmd>marks<cr>", { desc = "Marks" })

---------------------------------------------------------------------------
-- Explorer: netrw as a tree sidebar on the left (like LazyVim's), with
-- LazyVim-style keys for file operations.
---------------------------------------------------------------------------
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3 -- tree
vim.g.netrw_fastbrowse = 0 -- always re-read folders, so changes show up
vim.g.netrw_browse_split = 4 -- open files in the window you came from
vim.g.netrw_list_hide = [[^\./$,^\.git/$]]
vim.g.netrw_hide = 1

local explorer = { selected = {} }
local ns_sel = api.nvim_create_namespace("explorer_selected")
local function short(p) return fn.fnamemodify(p, ":~:.") end
local function abspath(p) return (fn.simplify(fn.fnamemodify(p, ":p")):gsub("/$", "")) end -- no "..", no trailing /

local function ex_top() return vim.w.netrw_treetop or vim.b.netrw_curdir or fn.getcwd() end
-- Every line of the tree as { path, depth, dir }. Line 1 is "../", then the
-- top folder at depth 0, then its contents indented with "| " per level.
-- Folders end in "/", so no disk access is needed (it's slow on the mount).
local function ex_entries()
  local top = ex_top()
  local entries, stack = {}, { [0] = top }
  for i, line in ipairs(api.nvim_buf_get_lines(0, 0, -1, false)) do
    local depth = 0
    while line:sub(depth * 2 + 1, depth * 2 + 2) == "| " do depth = depth + 1 end
    local name = line:sub(depth * 2 + 1):gsub("[*@=|]$", "")
    if name == "../" then
      entries[i] = { path = fn.fnamemodify(top, ":h"), depth = -1, dir = true, up = true }
    elseif name ~= "" then
      local path = depth == 0 and top or (stack[depth - 1] .. "/" .. name:gsub("/$", ""))
      stack[depth] = path -- only folders have deeper lines, so files never get used here
      entries[i] = { path = path, depth = depth, dir = name:sub(-1) == "/" }
    end
  end
  return entries
end
local function ex_cur() return ex_entries()[fn.line(".")] end
local function ex_editable(e) return e and not e.up and e.depth > 0 end
local function ex_expanded(path) return vim.w.netrw_treedict ~= nil and vim.w.netrw_treedict[path] ~= nil end
local function ex_target_dir() -- the folder under the cursor, or the folder of the file under it
  local e = ex_cur()
  if not e then return ex_top() end
  return e.dir and e.path or fn.fnamemodify(e.path, ":h")
end
local function netrw_key(keys) vim.cmd('execute "normal ' .. keys .. '"') end -- uses netrw's own maps
local function netrw_toggle() netrw_key([[\<Plug>NetrwLocalBrowseCheck]]) end -- netrw's Enter: expand / collapse / go up

local function ex_paint()
  api.nvim_buf_clear_namespace(0, ns_sel, 0, -1)
  if next(explorer.selected) == nil then return end
  for i, e in pairs(ex_entries()) do
    if explorer.selected[e.path] then api.nvim_buf_add_highlight(0, ns_sel, "Visual", i - 1, 0, -1) end
  end
end
-- Put the cursor on path, expanding folders on the way if expand is set.
-- If it can't be shown, stop on its closest visible folder.
local function ex_reveal(path, expand)
  for _ = 1, 30 do
    local best, best_depth, best_path = nil, -2, nil
    for i, e in pairs(ex_entries()) do
      if e.path == path then
        fn.cursor(i, 1)
        return
      end
      if e.dir and not e.up and path:sub(1, #e.path + 1) == e.path .. "/" and e.depth > best_depth then
        best, best_depth, best_path = i, e.depth, e.path
      end
    end
    if not best then return end
    fn.cursor(best, 1)
    if not expand or ex_expanded(best_path) then return end
    netrw_toggle()
  end
end
-- Rebuild the tree from disk. netrw's own refresh is buggy in tree mode (folders
-- lose their "/"), so clear its cache, reopen, and re-expand what was open.
local function ex_refresh(focus)
  local top = ex_top()
  local open = vim.tbl_keys(vim.w.netrw_treedict or {})
  table.sort(open) -- parents before children
  local line = fn.line(".")
  vim.w.netrw_treedict = vim.empty_dict()
  vim.cmd("Explore " .. fn.fnameescape(top))
  for _, dir in ipairs(open) do
    if dir ~= top and fn.isdirectory(dir) == 1 then
      ex_reveal(dir, true)
      local e = ex_cur()
      if e and e.path == dir and not ex_expanded(dir) then netrw_toggle() end
    end
  end
  if focus then ex_reveal(focus, true) else fn.cursor(math.min(line, fn.line("$")), 1) end
  ex_paint()
end
-- A one-line y/N question. (A multi-line confirm() leaves Neovim 0.8 showing
-- the old screen afterwards.)
local function ex_ask(question, paths, on_yes)
  local names = table.concat(vim.tbl_map(function(p) return fn.fnamemodify(p, ":t") end, paths), ", ")
  if #names > 50 then names = #paths .. " items" end
  vim.ui.input({ prompt = question:format(names) .. " (y/N) " }, function(a)
    if a and a:lower():sub(1, 1) == "y" then on_yes() end
  end)
end
local function ex_buffers_under(path) -- buffers for path, or for files inside it if it's a folder
  return vim.tbl_filter(function(b)
    local name = api.nvim_buf_get_name(b)
    return name == path or name:sub(1, #path + 1) == path .. "/"
  end, api.nvim_list_bufs())
end
local function ex_wipe(path) -- drop the buffers for files that are gone, keeping their windows
  for _, b in ipairs(ex_buffers_under(path)) do
    if not vim.bo[b].modified then
      for _, w in ipairs(fn.win_findbuf(b)) do
        api.nvim_win_call(w, function()
          local alt = fn.bufnr("#")
          vim.cmd((alt > 0 and alt ~= b and fn.buflisted(alt) == 1) and ("buffer " .. alt) or "enew")
        end)
      end
      pcall(vim.cmd, "bwipeout " .. b)
    end
  end
end
local function ex_moved(old, new) -- point open buffers at a renamed or moved file / folder
  for _, b in ipairs(ex_buffers_under(old)) do
    if not vim.bo[b].modified then
      if pcall(api.nvim_buf_set_name, b, new .. api.nvim_buf_get_name(b):sub(#old + 1)) then
        api.nvim_buf_call(b, function() vim.cmd("silent! edit!") end)
      end
    end
  end
end
local function ex_selection_or_cursor()
  local paths = vim.tbl_keys(explorer.selected)
  local e = ex_cur()
  if #paths == 0 and ex_editable(e) then paths = { e.path } end
  table.sort(paths)
  return paths
end
local function copy_path(src, dst) -- shows an error if it fails
  local ok, err
  if fn.isdirectory(src) == 1 then
    fn.system({ "cp", "-R", src, dst })
    ok, err = vim.v.shell_error == 0, "cp -R failed"
  else
    ok, err = vim.loop.fs_copyfile(src, dst)
  end
  if not ok then vim.notify(("Copy %s: %s"):format(short(src), err), vim.log.levels.ERROR) end
end

local explorer_actions = {
  add = function()
    local base = ex_target_dir()
    vim.ui.input({ prompt = "New file (end with / for a folder) in " .. short(base) .. "/: " }, function(name)
      if not name or name == "" then return end
      local path = base .. "/" .. name
      if name:sub(-1) == "/" then
        fn.mkdir(path, "p")
      else
        fn.mkdir(fn.fnamemodify(path, ":h"), "p")
        local f = io.open(path, "a")
        if f then f:close() end
      end
      ex_refresh(abspath(path))
    end)
  end,
  rename = function()
    local e = ex_cur()
    if not ex_editable(e) then return end
    local parent = fn.fnamemodify(e.path, ":h")
    vim.ui.input({ prompt = "Rename to: ", default = fn.fnamemodify(e.path, ":t") }, function(new)
      if not new or new == "" then return end
      local dst = parent .. "/" .. new
      fn.mkdir(fn.fnamemodify(dst, ":h"), "p")
      local ok, err = vim.loop.fs_rename(e.path, dst)
      if not ok then return vim.notify(err, vim.log.levels.ERROR) end
      dst = abspath(dst)
      ex_moved(e.path, dst)
      ex_refresh(dst)
    end)
  end,
  delete = function()
    local paths = ex_selection_or_cursor()
    if #paths == 0 then return end
    ex_ask("Delete %s permanently?", paths, function()
      for _, p in ipairs(paths) do
        fn.delete(p, "rf")
        ex_wipe(p)
      end
      explorer.selected = {}
      ex_refresh()
    end)
  end,
  copy = function()
    local paths = vim.tbl_keys(explorer.selected)
    if #paths > 0 then -- copy the selection into the folder under the cursor
      local dst = ex_target_dir()
      for _, p in ipairs(paths) do copy_path(p, dst .. "/" .. fn.fnamemodify(p, ":t")) end
      explorer.selected = {}
      return ex_refresh(dst)
    end
    local e = ex_cur()
    if not ex_editable(e) then return end
    vim.ui.input({ prompt = "Copy to: ", default = fn.fnamemodify(e.path, ":t") }, function(new)
      if not new or new == "" then return end
      local dst = fn.fnamemodify(e.path, ":h") .. "/" .. new
      fn.mkdir(fn.fnamemodify(dst, ":h"), "p")
      copy_path(e.path, dst)
      ex_refresh(abspath(dst))
    end)
  end,
  move = function()
    local paths = vim.tbl_keys(explorer.selected)
    if #paths == 0 then return vim.notify("Select files with Tab first, then put the cursor on a folder") end
    local dst = ex_target_dir()
    ex_ask("Move %s into " .. fn.fnamemodify(dst, ":t") .. "/?", paths, function()
      for _, p in ipairs(paths) do
        local to = dst .. "/" .. fn.fnamemodify(p, ":t")
        local ok, err = vim.loop.fs_rename(p, to)
        if ok then ex_moved(p, to) else vim.notify(("Move %s: %s"):format(short(p), err), vim.log.levels.ERROR) end
      end
      explorer.selected = {}
      ex_refresh(dst)
    end)
  end,
  select = function()
    local e = ex_cur()
    if ex_editable(e) then
      explorer.selected[e.path] = (not explorer.selected[e.path]) or nil
      ex_paint()
    end
    vim.cmd("normal! j")
  end,
  open = function() -- folders and ../: expand (or step into it if it's open), go up
    local e = ex_cur()
    if ex_editable(e) and e.dir and ex_expanded(e.path) then return vim.cmd("normal! j") end
    netrw_toggle()
  end,
  close = function() -- h: collapse this folder, or the folder this file is in
    local e = ex_cur()
    if not e or e.depth <= 0 then return end
    if not (e.dir and ex_expanded(e.path)) then
      if e.depth == 1 then return end -- its folder is the top of the tree
      ex_reveal(fn.fnamemodify(e.path, ":h"))
    end
    netrw_toggle()
  end,
}

-- The sidebar. Files open in the window you were in before, and it stays open.
local function explorer_win()
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if vim.w[w].explorer then return w end
  end
end
-- The window files go to: the last one used if it shows a file, else the
-- first that does (so never the explorer, quickfix, help or a float).
local function main_win()
  local function shows_file(w)
    return w ~= 0 and not vim.w[w].explorer and api.nvim_win_get_config(w).relative == ""
      and vim.bo[api.nvim_win_get_buf(w)].buftype == ""
  end
  local prev = fn.win_getid(fn.winnr("#"))
  if shows_file(prev) then return prev end
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if shows_file(w) then return w end
  end
end
local function unstyle(w) -- make a window split off the sidebar (or the sidebar itself) a normal one
  vim.w[w].explorer = nil
  vim.wo[w].winfixwidth = false
  vim.wo[w].winhighlight = ""
end
local function main_win_or_split() -- makes a main window if the explorer is the only one
  local w = main_win()
  if w then return w end
  local from = api.nvim_get_current_win()
  vim.cmd("botright vsplit")
  w = api.nvim_get_current_win()
  unstyle(w)
  api.nvim_set_current_win(from)
  return w
end
local function explorer_close()
  local w = explorer_win()
  if not w then return end
  if #api.nvim_tabpage_list_wins(0) > 1 then return api.nvim_win_close(w, false) end
  -- It's the only window: turn it back into a normal one.
  unstyle(w)
  vim.cmd.enew()
end
local function explorer_open(dir)
  local w = explorer_win()
  if w then
    if w == api.nvim_get_current_win() then return explorer_close() end
    api.nvim_win_close(w, false) -- reopen it, showing this file
  end
  local file = fn.expand("%:p")
  vim.cmd("topleft vertical 32new")
  vim.bo.bufhidden = "wipe" -- the empty buffer netrw replaces
  vim.w.explorer = true
  vim.wo.winfixwidth = true
  vim.wo.winhighlight = "Normal:ExplorerNormal,CursorLine:ExplorerCursorLine,SignColumn:ExplorerNormal"
  vim.cmd("Explore " .. fn.fnameescape(dir))
  if file ~= "" and file:sub(1, #dir + 1) == dir .. "/" then ex_reveal(file, true) else fn.cursor(2, 1) end
  ex_paint()
end
-- :q in the last file window quits, instead of leaving just the explorer.
api.nvim_create_autocmd("QuitPre", {
  callback = function()
    local cur = api.nvim_get_current_win()
    if vim.w[cur].explorer then return end
    local others = vim.tbl_filter(function(w)
      return w ~= cur and api.nvim_win_get_config(w).relative == ""
    end, api.nvim_tabpage_list_wins(0))
    if #others == 1 and vim.w[others[1]].explorer then api.nvim_win_close(others[1], true) end
  end,
})
-- Saving a brand-new file adds it to the tree.
api.nvim_create_autocmd("BufWritePre", {
  callback = function(ev) -- only check the disk when there's a tree to update
    vim.b[ev.buf].ex_new = explorer_win() ~= nil and fn.filereadable(fn.fnamemodify(ev.match, ":p")) == 0
  end,
})
api.nvim_create_autocmd("BufWritePost", {
  callback = function(ev)
    local w = explorer_win()
    if w and vim.b[ev.buf].ex_new then api.nvim_win_call(w, ex_refresh) end
  end,
})
-- l / Enter: files open in the main window (netrw would use whichever window
-- was last, even quickfix or help); folders are left to netrw.
local function explorer_enter()
  local e = ex_cur()
  if not ex_editable(e) or e.dir then return explorer_actions.open() end
  api.nvim_set_current_win(main_win_or_split())
  vim.cmd("edit " .. fn.fnameescape(e.path))
end
map("n", "<leader>e", function() explorer_open(fn.getcwd()) end, { desc = "Explorer" })
map("n", "<leader>E", function() explorer_open(fn.expand("%:p:h")) end, { desc = "Explorer (this file's folder)" })

-- If a file opens in the explorer window (Space Space, Shift-h/l, gf, ]q...
-- while the sidebar has focus), move it to the main window and rebuild the tree.
api.nvim_create_autocmd("BufWinEnter", {
  callback = function(ev)
    local win = api.nvim_get_current_win()
    local function is_file(b) -- not netrw, a folder (netrw is about to list it) or a special buffer
      return api.nvim_buf_is_valid(b) and vim.bo[b].filetype ~= "netrw" and vim.bo[b].buftype == ""
        and fn.isdirectory(api.nvim_buf_get_name(b)) == 0
    end
    if not vim.w[win].explorer or not is_file(ev.buf) then return end
    vim.schedule(function()
      if not api.nvim_win_is_valid(win) or api.nvim_win_get_buf(win) ~= ev.buf or not is_file(ev.buf) then return end
      api.nvim_set_current_win(win)
      local target = main_win_or_split()
      ex_refresh() -- puts the tree back, with the same folders open
      api.nvim_win_set_buf(target, ev.buf)
      api.nvim_set_current_win(target)
    end)
  end,
})

api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function(ev)
    local function bmap(lhs, rhs, desc, remap)
      map("n", lhs, rhs, { buffer = ev.buf, nowait = true, remap = remap, desc = desc })
    end
    bmap("l", explorer_enter, "Open / expand")
    bmap("<CR>", explorer_enter, "Open / expand")
    bmap("h", explorer_actions.close, "Collapse")
    bmap("<BS>", "-", "Up a folder", true)
    bmap("a", explorer_actions.add, "Add file / folder/")
    bmap("r", explorer_actions.rename, "Rename")
    bmap("d", explorer_actions.delete, "Delete")
    bmap("c", explorer_actions.copy, "Copy")
    bmap("m", explorer_actions.move, "Move selection here")
    bmap("<Tab>", explorer_actions.select, "Select")
    bmap("q", explorer_close, "Close explorer")
    -- Shift-h / Shift-l switch buffers in the main window, not the sidebar.
    for key, cmd in pairs({ ["<S-h>"] = "bprevious", ["<S-l>"] = "bnext" }) do
      bmap(key, function()
        local w = main_win()
        if w then
          api.nvim_set_current_win(w)
          vim.cmd(cmd)
        end
      end, "Buffer in main window")
    end
    bmap("u", function() ex_refresh() end, "Refresh")
    for _, d in ipairs({ "h", "j", "k", "l" }) do
      bmap("<C-" .. d .. ">", function() navigate(d) end, "Go to window/pane " .. d)
    end
    vim.schedule(function()
      if fn.line(".") == 1 and fn.line("$") > 1 then fn.cursor(2, 1) end -- skip "../"
      ex_paint()
    end)
  end,
})

---------------------------------------------------------------------------
-- Floating prompts: the : command line and every text prompt pop up in the
-- middle of the screen, like LazyVim (which uses the noice plugin for it).
---------------------------------------------------------------------------
local function close_wins(wins)
  for _, w in ipairs(wins) do
    if api.nvim_win_is_valid(w) then api.nvim_win_close(w, true) end
  end
end
local function feed(keys) api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, false, true), "n", false) end
-- A key for Insert mode: moves in the completion menu when it's open, else runs f.
local function pum_or(keys, f)
  return function()
    if fn.pumvisible() == 1 then feed(keys) else f() end
  end
end

-- A title drawn over a float's top border (floats can't have titles in 0.8).
local function border_title(row, col, text)
  text = " " .. text .. " "
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  local win = api.nvim_open_win(buf, false, {
    relative = "editor", row = row, col = col + 2, width = fn.strdisplaywidth(text), height = 1,
    style = "minimal", focusable = false, zindex = 60, noautocmd = true,
  })
  vim.wo[win].winhighlight = "Normal:PickerTitle"
  return win
end

-- prompt{ title, default, filetype, width, on_submit(text), on_cancel(), keys(buf) }
local function prompt(opts)
  local width = opts.width or math.min(vim.o.columns - 6, math.max(50, fn.strdisplaywidth(opts.title) + 8))
  local row, col = math.floor(vim.o.lines * 0.25), math.floor((vim.o.columns - width) / 2)
  local origin = api.nvim_get_current_win()
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = api.nvim_open_win(buf, true, {
    relative = "editor", row = row, col = col, width = width, height = 1, style = "minimal", border = "rounded",
  })
  local title = border_title(row, col, opts.title)
  if opts.filetype then vim.bo[buf].filetype = opts.filetype end
  api.nvim_buf_set_lines(buf, 0, -1, false, { opts.default or "" })

  local done = false
  local function finish(submit)
    if done then return end
    done = true
    local text = api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    vim.cmd("stopinsert")
    vim.schedule(function() -- once Insert mode has ended, so the cursor doesn't shift
      close_wins({ win, title })
      if api.nvim_win_is_valid(origin) then api.nvim_set_current_win(origin) end
      if submit then opts.on_submit(text) elseif opts.on_cancel then opts.on_cancel() end
    end)
  end
  local function bmap(modes, lhs, f) map(modes, lhs, f, { buffer = buf, nowait = true }) end
  bmap({ "i", "n" }, "<CR>", function() finish(true) end)
  bmap({ "i", "n" }, "<Esc>", function() finish(false) end)
  bmap({ "i", "n" }, "<C-c>", function() finish(false) end)
  api.nvim_create_autocmd("BufLeave", { buffer = buf, once = true, callback = function() finish(false) end })
  if opts.keys then opts.keys(buf) end
  vim.cmd("startinsert!")
end

-- Every vim.ui.input (rename, add file, grep, y/N questions...) uses it.
vim.ui.input = function(opts, on_confirm)
  opts = opts or {}
  local title = (opts.prompt or "Input"):gsub("[%s:]*$", "")
  prompt({
    title = title, default = opts.default,
    on_submit = on_confirm, on_cancel = function() on_confirm(nil) end,
  })
end

-- Up/Down (and Ctrl-p/Ctrl-n) history in a prompt, like the real command
-- line: only entries starting with what you've typed. kind is ":" or "/".
local function history_keys(buf, kind)
  local hist_i, hist_prefix, setting = 0, "", false
  local function set(text)
    setting = true
    api.nvim_buf_set_lines(buf, 0, -1, false, { text })
    api.nvim_win_set_cursor(0, { 1, #text })
  end
  -- Typing starts history over from what's in the box.
  api.nvim_create_autocmd("TextChangedI", {
    buffer = buf,
    callback = function()
      if not setting then hist_i = 0 end
      setting = false
    end,
  })
  local function history(step)
    if hist_i == 0 then hist_prefix = api.nvim_get_current_line() end
    local i = hist_i
    while true do
      i = i + step
      if i <= 0 then
        hist_i = 0
        return set(hist_prefix)
      end
      local h = fn.histget(kind, -i)
      if h == "" then return end
      if h:sub(1, #hist_prefix) == hist_prefix then
        hist_i = i
        return set(h)
      end
    end
  end
  map("i", "<Up>", function() history(1) end, { buffer = buf })
  map("i", "<Down>", function() history(-1) end, { buffer = buf })
  map("i", "<C-p>", pum_or("<C-p>", function() history(1) end), { buffer = buf })
  map("i", "<C-n>", pum_or("<C-n>", function() history(-1) end), { buffer = buf })
end

-- The : command line. What you type is handed to the real command line when
-- you press Enter, so ranges, history, @: and errors all work as normal.
local function cmdline(default)
  local word, WORD = fn.expand("<cword>"), fn.expand("<cWORD>")
  prompt({
    title = "Cmdline", default = default, filetype = "vim", width = math.min(80, vim.o.columns - 6),
    on_submit = function(text)
      -- "t": as if typed, so it goes into history and @: repeats it. "i": before
      -- any keys you typed after Enter, so they run afterwards.
      if text:match("%S") then api.nvim_feedkeys(":" .. text .. "\r", "nti", false) end
    end,
    keys = function(buf)
      history_keys(buf, ":")
      local function complete()
        local line = api.nvim_get_current_line():sub(1, api.nvim_win_get_cursor(0)[2])
        local items = fn.getcompletion(line, "cmdline")
        if #items == 0 then return end
        local last_space = line:match(".*()%s")
        fn.complete(last_space and last_space + 1 or 1, items)
        feed("<C-n>")
      end
      map("i", "<Tab>", pum_or("<C-n>", complete), { buffer = buf })
      map("i", "<S-Tab>", pum_or("<C-p>", function() end), { buffer = buf })
      map("i", "<C-r><C-w>", function() return word end, { buffer = buf, expr = true })
      map("i", "<C-r><C-a>", function() return WORD end, { buffer = buf, expr = true })
    end,
  })
end
map("n", ":", function()
  cmdline(vim.v.count > 0 and (".,.+" .. (vim.v.count - 1)) or "")
end, { desc = "Command line" })
map("x", ":", function()
  vim.cmd([[execute "normal! \<Esc>"]])
  cmdline("'<,'>")
end, { desc = "Command line (selection)" })

-- / and ? searches. While you type, every match is highlighted and the view
-- jumps to the next one, with a count. Enter hands the search to the real /
-- (so n, N, history and highlighting work as normal); Esc puts the view back.
-- After an operator (d/foo, c/foo) and in Visual mode the real / is used.
local ns_search = api.nvim_create_namespace("search_box")
local function search_box(dir)
  local win, view = api.nvim_get_current_win(), fn.winsaveview()
  local count = vim.v.count > 0 and tostring(vim.v.count) or ""
  local ids = {}
  local function clear()
    for _, id in ipairs(ids) do pcall(fn.matchdelete, id, win) end
    ids = {}
  end
  local function restore() -- remove the preview and put the view back
    clear()
    fn.winrestview(view)
  end
  local function preview(buf)
    local pat = api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    clear()
    api.nvim_buf_clear_namespace(buf, ns_search, 0, -1)
    local label, hl = "", "Comment"
    api.nvim_win_call(win, function()
      fn.winrestview(view)
      if pat == "" then return end
      local p = pat -- follow 'ignorecase' / 'smartcase' like the real search
      if vim.o.ignorecase and not (vim.o.smartcase and p:find("%u")) then p = "\\c" .. p end
      local ok, pos = pcall(fn.searchpos, p, dir == "/" and "n" or "bn")
      if not ok or pos[1] == 0 then
        label, hl = ok and "no match" or "bad pattern", "ErrorMsg"
        return
      end
      fn.cursor(pos[1], pos[2])
      local ok1, all = pcall(fn.matchadd, "Search", p, 10)
      if ok1 then table.insert(ids, all) end
      local ok2, cur = pcall(fn.matchadd, "IncSearch", ("\\%%%dl\\%%%dc\\%%(%s\\)"):format(pos[1], pos[2], p), 11)
      if ok2 then table.insert(ids, cur) end
      local sc = fn.searchcount({ pattern = p, maxcount = 999, timeout = 100 })
      if sc.total and sc.total > 0 then label = ("%d/%d"):format(sc.current, sc.total) end
    end)
    if label ~= "" then
      api.nvim_buf_set_extmark(buf, ns_search, 0, 0, { virt_text = { { label, hl } }, virt_text_pos = "right_align" })
    end
  end
  prompt({
    title = dir == "/" and "Search" or "Search backward", width = math.min(70, vim.o.columns - 6),
    on_submit = function(text)
      restore()
      api.nvim_feedkeys(count .. dir .. text .. "\r", "nti", false)
    end,
    on_cancel = restore,
    keys = function(buf)
      history_keys(buf, "/")
      api.nvim_create_autocmd("TextChangedI", { buffer = buf, callback = function() preview(buf) end })
    end,
  })
end
map("n", "/", function() search_box("/") end, { desc = "Search forward" })
map("n", "?", function() search_box("?") end, { desc = "Search backward" })

---------------------------------------------------------------------------
-- Picker: a small fuzzy finder in a floating window (Space Space etc.)
---------------------------------------------------------------------------
local ns_pick = api.nvim_create_namespace("picker")

-- pick{ title, items = { "text", ... }, on_choose = function(item, how) }
-- how is "edit", "vsplit" or "split".
local function pick(opts)
  local items = opts.items
  local width = math.min(100, math.floor(vim.o.columns * 0.8))
  local height = math.min(20, math.floor(vim.o.lines * 0.6))
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height - 3) / 3)

  local list_buf = api.nvim_create_buf(false, true)
  local list_win = api.nvim_open_win(list_buf, false, {
    relative = "editor", row = row + 3, col = col, width = width, height = height,
    style = "minimal", border = "rounded", focusable = false,
  })
  vim.wo[list_win].cursorline = false
  local input_buf = api.nvim_create_buf(false, true)
  local input_win = api.nvim_open_win(input_buf, true, {
    relative = "editor", row = row, col = col, width = width, height = 1,
    style = "minimal", border = "rounded",
  })
  local title_win = border_title(row, col, opts.title)

  local shown, sel, closed = {}, 1, false
  local function render()
    local query = api.nvim_buf_get_lines(input_buf, 0, 1, false)[1] or ""
    local positions = {}
    if query == "" then
      shown = vim.list_slice(items, 1, 500)
    else
      local res = fn.matchfuzzypos(items, query)
      shown, positions = vim.list_slice(res[1], 1, 500), res[2]
    end
    sel = math.max(1, math.min(sel, #shown))
    api.nvim_buf_set_lines(list_buf, 0, -1, false, #shown > 0 and shown or { "  (no matches)" })
    api.nvim_buf_clear_namespace(list_buf, ns_pick, 0, -1)
    for i = 1, #shown do
      for _, p in ipairs(positions[i] or {}) do
        api.nvim_buf_add_highlight(list_buf, ns_pick, "PickerMatch", i - 1, p, p + 1)
      end
    end
    if #shown > 0 then
      api.nvim_buf_set_extmark(list_buf, ns_pick, sel - 1, 0, { line_hl_group = "PickerSel" })
      api.nvim_win_set_cursor(list_win, { sel, 0 })
    end
    api.nvim_buf_clear_namespace(input_buf, ns_pick, 0, -1)
    api.nvim_buf_set_extmark(input_buf, ns_pick, 0, 0, {
      virt_text = { { ("%d/%d"):format(#shown, #items), "Comment" } },
      virt_text_pos = "right_align",
    })
  end
  local function close()
    if closed then return end
    closed = true
    vim.cmd("stopinsert")
    close_wins({ input_win, list_win, title_win })
  end
  local function choose(how)
    local item = shown[sel]
    close()
    if item then vim.schedule(function() opts.on_choose(item, how) end) end
  end
  local function move(delta)
    if #shown == 0 then return end
    sel = (sel - 1 + delta) % #shown + 1
    render()
  end

  local function imap(lhs, f) map({ "i", "n" }, lhs, f, { buffer = input_buf, nowait = true }) end
  for _, k in ipairs({ "<C-j>", "<C-n>", "<Down>" }) do imap(k, function() move(1) end) end
  for _, k in ipairs({ "<C-k>", "<C-p>", "<Up>" }) do imap(k, function() move(-1) end) end
  imap("<CR>", function() choose("edit") end)
  imap("<C-v>", function() choose("vsplit") end)
  imap("<C-s>", function() choose("split") end)
  imap("<C-c>", close)
  imap("<Esc>", close)
  api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, { buffer = input_buf, callback = function() sel = 1; render() end })
  api.nvim_create_autocmd("BufLeave", { buffer = input_buf, once = true, callback = close })

  render()
  vim.cmd("startinsert")
end

local function open_file(path, how) vim.cmd(how .. " " .. fn.fnameescape(path)) end

local function project_files()
  local files = fn.systemlist({ "git", "ls-files", "--cached", "--others", "--exclude-standard" })
  if vim.v.shell_error ~= 0 then
    files = fn.systemlist({ "find", ".", "-type", "f", "-not", "-path", "*/.git/*" })
    return vim.tbl_map(function(f) return (f:gsub("^%./", "")) end, files)
  end
  -- Drop files git still tracks but that were deleted (one git call, not a disk
  -- check per file, which is slow on the container's mount).
  local deleted = {}
  for _, f in ipairs(fn.systemlist({ "git", "ls-files", "--deleted" })) do deleted[f] = true end
  return vim.tbl_filter(function(f) return not deleted[f] end, files)
end

-- Files opened this session, newest first. (v:oldfiles is only updated when
-- Neovim quits, so on its own it would miss them.)
local session_files = {}
api.nvim_create_autocmd("BufEnter", {
  callback = function(ev)
    local name = api.nvim_buf_get_name(ev.buf)
    if name == "" or vim.bo[ev.buf].buftype ~= "" then return end
    for i, f in ipairs(session_files) do
      if f == name then table.remove(session_files, i) break end
    end
    table.insert(session_files, 1, name)
  end,
})

local pickers = {
  files = function()
    pick({ title = "Files", items = project_files(), on_choose = open_file })
  end,
  buffers = function()
    local cur = api.nvim_get_current_buf()
    local infos = fn.getbufinfo({ buflisted = 1 })
    table.sort(infos, function(a, b) return a.lastused > b.lastused end)
    local items = {}
    for _, b in ipairs(infos) do
      if b.bufnr ~= cur and b.name ~= "" then table.insert(items, short(b.name)) end
    end
    pick({ title = "Buffers", items = items, on_choose = open_file })
  end,
  recent = function()
    local current = fn.expand("%:p")
    local items, seen = {}, {}
    for _, f in ipairs(vim.list_extend(vim.list_extend({}, session_files), vim.v.oldfiles)) do
      if f ~= current and not seen[f] and fn.filereadable(f) == 1 then
        seen[f] = true
        table.insert(items, short(f))
      end
    end
    pick({ title = "Recent", items = items, on_choose = open_file })
  end,
  keymaps = function() -- a which-key stand-in: every Space key with its description
    local items, lhs_of = {}, {}
    local maps = vim.list_extend(api.nvim_get_keymap("n"), api.nvim_buf_get_keymap(0, "n"))
    for _, m in ipairs(maps) do
      if m.desc and m.lhs:sub(1, 1) == " " then
        local text = ("Space %-6s %s"):format(m.lhs:sub(2), m.desc)
        lhs_of[text] = m.lhs
        table.insert(items, text)
      end
    end
    table.sort(items)
    pick({ title = "Keys", items = items, on_choose = function(item)
      api.nvim_feedkeys(api.nvim_replace_termcodes(lhs_of[item], true, false, true), "m", false)
    end })
  end,
}
map("n", "<leader><space>", pickers.files, { desc = "Find files" })
map("n", "<leader>ff", pickers.files, { desc = "Find files" })
map("n", "<leader>,", pickers.buffers, { desc = "Buffers" })
map("n", "<leader>fb", pickers.buffers, { desc = "Buffers" })
map("n", "<leader>fr", pickers.recent, { desc = "Recent files" })
map("n", "<leader>?", pickers.keymaps, { desc = "Search Space keys" })
map("n", "<leader>sk", pickers.keymaps, { desc = "Search Space keys" })

---------------------------------------------------------------------------
-- Grep and quickfix. ripgrep if it exists, otherwise GNU grep.
---------------------------------------------------------------------------
local has_rg = fn.executable("rg") == 1
local rg_base = { "rg", "--vimgrep", "--smart-case", "--hidden", "-g", "!.git" } -- shared with :grep
if has_rg then
  o.grepprg = table.concat(rg_base, " ")
  o.grepformat = "%f:%l:%c:%m"
else
  o.grepprg = "grep -rnIHP --exclude-dir=.git"
  o.grepformat = "%f:%l:%m"
end

-- The project the current file belongs to: the nearest folder above it with a
-- project file (go.mod etc.), else the folder nvim was started in. Like
-- LazyVim's "root": from a Go file in bookshelf/, grep searches bookshelf/.
local root_markers = { "go.mod", "package.json", "pyproject.toml", "Cargo.toml" }
local function project_root()
  local dir = fn.expand("%:p:h")
  local marker = fn.isdirectory(dir) == 1 and vim.fs.find(root_markers, { upward = true, path = dir })[1]
  return marker and vim.fs.dirname(marker) or fn.getcwd()
end
-- The folder to show and search: "." for the cwd, else relative to it.
local function project_dir()
  local rel = fn.fnamemodify(project_root(), ":.")
  return (rel == "" or rel == fn.getcwd()) and "." or rel
end

-- grep(pattern, { word = true, fixed = true }) searches the current project,
-- fills quickfix and opens it.
local function grep(pattern, flags)
  flags = flags or {}
  local args
  if has_rg then
    args = vim.list_extend({}, rg_base)
    if flags.fixed then table.insert(args, "-F") end
  else
    args = { "grep", "-rnIH", "--exclude-dir=.git", flags.fixed and "-F" or "-P" }
    if not pattern:find("%u") then table.insert(args, "-i") end -- smart case
  end
  if flags.word then table.insert(args, "-w") end
  local dir = flags.dir or project_dir()
  vim.list_extend(args, { "--", pattern, dir })
  local lines = vim.tbl_map(function(l) return (l:gsub("^%./", "")) end, fn.systemlist(args))
  local where = dir == "." and "" or " in " .. dir .. "/"
  fn.setqflist({}, " ", { title = "grep " .. pattern .. where, lines = lines, efm = vim.o.grepformat })
  if #lines == 0 then return vim.notify("No matches for " .. pattern .. where) end
  vim.cmd("botright copen")
end
local function grep_prompt()
  local dir = project_dir()
  vim.ui.input({ prompt = dir == "." and "Grep" or "Grep in " .. dir .. "/" }, function(p)
    if p and p ~= "" then grep(p, { dir = dir }) end
  end)
end
map("n", "<leader>/", grep_prompt, { desc = "Grep project" })
map("n", "<leader>sg", grep_prompt, { desc = "Grep project" })
map("n", "<leader>sw", function() grep(fn.expand("<cword>"), { word = true, fixed = true }) end, { desc = "Grep word under cursor" })
map("n", "<leader>st", function() grep([[\b(TODO|FIXME|FIX|HACK|NOTE)\b]]) end, { desc = "TODOs" })
map("n", "]q", "<cmd>silent! cnext<cr>", { desc = "Next quickfix" })
map("n", "[q", "<cmd>silent! cprevious<cr>", { desc = "Previous quickfix" })
map("n", "<leader>xq", function()
  for _, w in ipairs(fn.getwininfo()) do
    if w.quickfix == 1 and w.loclist == 0 then return vim.cmd.cclose() end
  end
  vim.cmd("botright copen")
end, { desc = "Toggle quickfix" })

---------------------------------------------------------------------------
-- Diagnostics and LSP (built-in client; only starts if the server exists)
---------------------------------------------------------------------------
vim.diagnostic.config({ virtual_text = true, severity_sort = true, float = { border = "rounded" } })
local S = vim.diagnostic.severity
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]e", function() vim.diagnostic.goto_next({ severity = S.ERROR }) end, { desc = "Next error" })
map("n", "[e", function() vim.diagnostic.goto_prev({ severity = S.ERROR }) end, { desc = "Previous error" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>xx", function()
  vim.diagnostic.setqflist({ open = false })
  vim.cmd("botright copen")
end, { desc = "All diagnostics (quickfix)" })

-- Space c m: check the Go module this file is in with `go vet` (which also
-- compiles it) and put every problem in quickfix. Works without gopls.
map("n", "<leader>cm", function()
  local marker = vim.fs.find("go.mod", { upward = true, path = fn.expand("%:p:h") })[1]
  if not marker then return vim.notify("Not inside a Go module (no go.mod above this file)") end
  local root = vim.fs.dirname(marker)
  local items = {}
  for _, line in ipairs(fn.systemlist({ "go", "-C", root, "vet", "./..." })) do
    local file, lnum, col, text = line:gsub("^vet: ", ""):match("^%.?/?([^:]+%.go):(%d+):(%d+): (.*)$")
    if file then
      table.insert(items, { filename = root .. "/" .. file, lnum = tonumber(lnum), col = tonumber(col), text = text })
    end
  end
  fn.setqflist({}, " ", { title = "go vet", items = items })
  if #items == 0 then
    vim.cmd("cclose")
    return vim.notify(vim.v.shell_error == 0 and "go vet: no problems" or "go vet failed (see :!go vet ./...)")
  end
  vim.cmd("botright copen")
end, { desc = "Check Go module (go vet)" })

local servers = {
  go = { cmd = { "gopls" }, root = { "go.mod", ".git" } },
  python = { cmd = { "pyright-langserver", "--stdio" }, root = { "pyproject.toml", "setup.py", ".git" } },
  typescript = { cmd = { "typescript-language-server", "--stdio" }, root = { "tsconfig.json", "package.json", ".git" } },
  lua = { cmd = { "lua-language-server" }, root = { ".git" } },
}
servers.javascript, servers.typescriptreact, servers.javascriptreact = servers.typescript, servers.typescript, servers.typescript

api.nvim_create_autocmd("FileType", {
  pattern = vim.tbl_keys(servers),
  callback = function(ev)
    local s = servers[vim.bo[ev.buf].filetype]
    if fn.executable(s.cmd[1]) ~= 1 then return end
    local marker = vim.fs.find(s.root, { upward = true, path = fn.fnamemodify(ev.file, ":p:h") })[1]
    vim.lsp.start({
      name = s.cmd[1],
      cmd = s.cmd,
      root_dir = marker and vim.fs.dirname(marker) or fn.getcwd(),
    })
  end,
})

api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    local function bmap(lhs, f, desc) map("n", lhs, f, { buffer = ev.buf, desc = desc }) end
    local lsp = vim.lsp.buf
    bmap("gd", lsp.definition, "Go to definition")
    bmap("gr", lsp.references, "References")
    bmap("gI", lsp.implementation, "Implementations")
    bmap("gy", lsp.type_definition, "Type definition")
    bmap("gD", lsp.declaration, "Declaration")
    bmap("K", lsp.hover, "Hover")
    bmap("gK", lsp.signature_help, "Signature help")
    bmap("gai", lsp.incoming_calls, "Incoming calls")
    bmap("gao", lsp.outgoing_calls, "Outgoing calls")
    bmap("<leader>cr", lsp.rename, "Rename symbol")
    bmap("<leader>ca", lsp.code_action, "Code action")
    bmap("<leader>cf", function() lsp.format({ async = false }) end, "Format")
    bmap("<leader>ss", lsp.document_symbol, "Symbols in file")
    bmap("<leader>sS", function()
      vim.ui.input({ prompt = "Workspace symbol: " }, function(q) if q then lsp.workspace_symbol(q) end end)
    end, "Symbols in workspace")
    map("i", "<C-Space>", "<C-x><C-o>", { buffer = ev.buf, desc = "Complete" })
  end,
})

-- Go: on save, organise imports + format with gopls, or plain gofmt without it.
api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function(ev)
    local client = vim.lsp.get_active_clients({ bufnr = ev.buf, name = "gopls" })[1]
    if client then
      local params = vim.lsp.util.make_range_params()
      params.context = { only = { "source.organizeImports" } }
      local res = vim.lsp.buf_request_sync(ev.buf, "textDocument/codeAction", params, 1000)
      for _, r in pairs(res or {}) do
        for _, action in pairs(r.result or {}) do
          if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding) end
        end
      end
      vim.lsp.buf.format({ async = false, bufnr = ev.buf })
    elseif fn.executable("gofmt") == 1 then
      local lines = api.nvim_buf_get_lines(ev.buf, 0, -1, false)
      local out = fn.systemlist({ "gofmt" }, lines)
      if vim.v.shell_error == 0 and not vim.deep_equal(out, lines) then
        local view = fn.winsaveview()
        api.nvim_buf_set_lines(ev.buf, 0, -1, false, out)
        fn.winrestview(view)
      end
    end
  end,
})

---------------------------------------------------------------------------
-- Commenting: gc + motion, gcc for a line, gc in visual mode
---------------------------------------------------------------------------
local function toggle_comment(first, last)
  local left, right = vim.bo.commentstring:match("^(.-)%s*%%s%s*(.-)$")
  if not left or left == "" then return end
  local lines = api.nvim_buf_get_lines(0, first - 1, last, false)
  local esc = vim.pesc
  local indent, all_commented = math.huge, true
  for _, l in ipairs(lines) do
    if l:find("%S") then
      indent = math.min(indent, #l:match("^%s*"))
      if not l:match("^%s*" .. esc(left)) then all_commented = false end
    end
  end
  for i, l in ipairs(lines) do
    if l:find("%S") then
      if all_commented then
        l = l:gsub("^(%s*)" .. esc(left) .. " ?", "%1", 1)
        if right ~= "" then l = l:gsub(" ?" .. esc(right) .. "%s*$", "", 1) end
      else
        l = l:sub(1, indent) .. left .. " " .. l:sub(indent + 1) .. (right ~= "" and " " .. right or "")
      end
      lines[i] = l
    end
  end
  api.nvim_buf_set_lines(0, first - 1, last, false, lines)
end
_G.CommentOperator = function()
  toggle_comment(api.nvim_buf_get_mark(0, "[")[1], api.nvim_buf_get_mark(0, "]")[1])
end
map("n", "gc", function()
  vim.o.operatorfunc = "v:lua.CommentOperator"
  return "g@"
end, { expr = true, desc = "Comment (motion)" })
map("n", "gcc", function()
  vim.o.operatorfunc = "v:lua.CommentOperator"
  return "g@" .. vim.v.count1 .. "_"
end, { expr = true, desc = "Comment line" })
map("x", "gc", function()
  vim.cmd([[execute "normal! \<Esc>"]])
  toggle_comment(fn.line("'<"), fn.line("'>"))
end, { desc = "Comment selection" })

---------------------------------------------------------------------------
-- Floating terminal: Ctrl-/ toggles it (tmux sends Ctrl-/ as Ctrl-_)
---------------------------------------------------------------------------
local term = { buf = nil, win = nil }
local function toggle_terminal()
  if term.win and api.nvim_win_is_valid(term.win) then
    api.nvim_win_close(term.win, true)
    term.win = nil
    return
  end
  if not (term.buf and api.nvim_buf_is_valid(term.buf)) then term.buf = api.nvim_create_buf(false, true) end
  local w, h = math.floor(vim.o.columns * 0.85), math.floor(vim.o.lines * 0.8)
  term.win = api.nvim_open_win(term.buf, true, {
    relative = "editor", width = w, height = h, style = "minimal", border = "rounded",
    row = math.floor((vim.o.lines - h) / 2), col = math.floor((vim.o.columns - w) / 2),
  })
  if vim.bo[term.buf].buftype ~= "terminal" then fn.termopen(vim.o.shell) end
  vim.cmd("startinsert")
end
map({ "n", "t" }, "<C-/>", toggle_terminal, { desc = "Terminal" })
map({ "n", "t" }, "<C-_>", toggle_terminal, { desc = "Terminal" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Terminal normal mode" })

---------------------------------------------------------------------------
-- Sessions: saved per folder on quit, Space q s restores
---------------------------------------------------------------------------
local session_dir = fn.stdpath("state") .. "/sessions/"
local function session_file(dir) return session_dir .. (dir or fn.getcwd()):gsub("/", "%%") .. ".vim" end
-- A session can't bring the explorer back properly (it returns as a plain,
-- broken window), so leave it out when saving and clear it out after loading.
local function drop_explorer()
  for _, b in ipairs(api.nvim_list_bufs()) do
    if vim.bo[b].filetype == "netrw" or api.nvim_buf_get_name(b):match("NetrwTreeListing$") then
      if #api.nvim_list_wins() == 1 and api.nvim_get_current_buf() == b then vim.cmd.enew() end
      pcall(api.nvim_buf_delete, b, { force = true })
    end
  end
end
api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local real = vim.tbl_filter(function(b) return api.nvim_buf_get_name(b) ~= "" and vim.bo[b].buftype == "" end, listed_buffers())
    if #real == 0 then return end
    drop_explorer()
    fn.mkdir(session_dir, "p")
    vim.cmd("mksession! " .. fn.fnameescape(session_file()))
  end,
})
local function load_session(f)
  drop_explorer() -- an open explorer would stop the session's layout coming back
  vim.cmd("silent! source " .. fn.fnameescape(f))
  drop_explorer()
end
map("n", "<leader>qs", function()
  local f = session_file()
  if fn.filereadable(f) == 0 then return vim.notify("No saved session for this folder") end
  load_session(f)
end, { desc = "Restore session" })
map("n", "<leader>qS", function()
  local files = fn.glob(session_dir .. "*.vim", false, true)
  local mtime = {}
  for _, f in ipairs(files) do mtime[f] = fn.getftime(f) end
  table.sort(files, function(a, b) return mtime[a] > mtime[b] end)
  local items = vim.tbl_map(function(f) return (fn.fnamemodify(f, ":t:r"):gsub("%%", "/")) end, files)
  if #items == 0 then return vim.notify("No saved sessions yet (one is saved per folder when you quit)") end
  pick({ title = "Sessions", items = items, on_choose = function(dir)
    load_session(session_file(dir))
  end })
end, { desc = "Select session" })

---------------------------------------------------------------------------
-- Theme: Catppuccin Mocha, written out by hand since the plugin can't be
-- installed. Colours follow the official Catppuccin Neovim theme. Only plain
-- Unicode, so no Nerd Font needed.
---------------------------------------------------------------------------
local c = {
  rosewater = "#f5e0dc", flamingo = "#f2cdcd", pink = "#f5c2e7", mauve = "#cba6f7",
  red = "#f38ba8", maroon = "#eba0ac", peach = "#fab387", yellow = "#f9e2af",
  green = "#a6e3a1", teal = "#94e2d5", sky = "#89dceb", sapphire = "#74c7ec",
  blue = "#89b4fa", lavender = "#b4befe",
  text = "#cdd6f4", subtext1 = "#bac2de", subtext0 = "#a6adc8",
  overlay2 = "#9399b2", overlay1 = "#7f849c", overlay0 = "#6c7086",
  surface2 = "#585b70", surface1 = "#45475a", surface0 = "#313244",
  base = "#1e1e2e", mantle = "#181825", crust = "#11111b",
  cursorline = "#2a2b3c", -- surface0 blended into base, as Catppuccin does
}
local function theme()
  vim.cmd("highlight clear")
  vim.g.colors_name = "catppuccin-mocha-lite"
  local groups = {
    -- Editor
    Normal = { fg = c.text, bg = c.base }, NormalFloat = { fg = c.text, bg = c.mantle },
    FloatBorder = { fg = c.blue, bg = c.mantle }, NormalNC = { link = "Normal" },
    CursorLine = { bg = c.cursorline }, CursorLineNr = { fg = c.lavender, bold = true },
    LineNr = { fg = c.surface1 }, SignColumn = { bg = c.base }, ColorColumn = { bg = c.surface0 },
    WinSeparator = { fg = c.crust, bg = c.base }, VertSplit = { link = "WinSeparator" },
    Visual = { bg = c.surface1, bold = true }, Search = { fg = c.text, bg = "#3e5767" },
    IncSearch = { fg = c.crust, bg = c.sky }, CurSearch = { link = "IncSearch" },
    MatchParen = { fg = c.peach, bg = c.surface1, bold = true },
    NonText = { fg = c.overlay0 }, Whitespace = { fg = c.surface1 }, EndOfBuffer = { fg = c.base },
    Folded = { fg = c.blue, bg = c.surface0 }, Directory = { fg = c.blue }, Title = { fg = c.blue, bold = true },
    Pmenu = { fg = c.overlay2, bg = c.mantle }, PmenuSel = { fg = c.text, bg = c.surface0, bold = true },
    PmenuSbar = { bg = c.surface0 }, PmenuThumb = { bg = c.overlay0 }, WildMenu = { link = "PmenuSel" },
    ErrorMsg = { fg = c.red, bold = true }, WarningMsg = { fg = c.yellow }, MoreMsg = { fg = c.blue },
    Question = { fg = c.blue }, ModeMsg = { fg = c.text, bold = true }, MsgArea = { fg = c.text },
    SpellBad = { sp = c.red, undercurl = true }, SpellCap = { sp = c.yellow, undercurl = true },
    TermCursor = { fg = c.base, bg = c.rosewater },
    StatusLine = { fg = c.text, bg = c.mantle }, StatusLineNC = { fg = c.surface1, bg = c.mantle },
    TabLine = { fg = c.overlay0, bg = c.mantle }, TabLineFill = { bg = c.mantle },
    TabLineSel = { fg = c.text, bg = c.base, bold = true }, TabLineMark = { fg = c.mauve, bg = c.base },
    TabLineMod = { fg = c.peach, bg = c.mantle }, TabLineSelMod = { fg = c.peach, bg = c.base },
    -- Syntax
    Comment = { fg = c.overlay2, italic = true }, Constant = { fg = c.peach }, String = { fg = c.green },
    Character = { fg = c.teal }, Number = { fg = c.peach }, Boolean = { fg = c.peach }, Float = { fg = c.peach },
    Identifier = { fg = c.flamingo }, Function = { fg = c.blue },
    Statement = { fg = c.mauve }, Conditional = { fg = c.mauve }, Repeat = { fg = c.mauve },
    Label = { fg = c.sapphire }, Operator = { fg = c.sky }, Keyword = { fg = c.mauve },
    Exception = { fg = c.mauve }, PreProc = { fg = c.pink }, Include = { fg = c.mauve },
    Define = { fg = c.pink }, Macro = { fg = c.mauve }, Type = { fg = c.yellow }, StorageClass = { fg = c.yellow },
    Structure = { fg = c.yellow }, Typedef = { fg = c.yellow }, Special = { fg = c.pink },
    SpecialChar = { fg = c.pink }, Delimiter = { fg = c.overlay2 }, Tag = { fg = c.mauve },
    Underlined = { underline = true }, Error = { fg = c.red }, Todo = { fg = c.base, bg = c.yellow, bold = true },
    -- Go (Vim's built-in Go syntax)
    goFunction = { fg = c.blue }, goFunctionCall = { fg = c.blue }, goPackage = { fg = c.mauve },
    goImport = { fg = c.mauve }, goDeclaration = { fg = c.mauve }, goDeclType = { fg = c.mauve },
    goBuiltins = { fg = c.red }, goType = { fg = c.yellow }, goSignedInts = { fg = c.yellow },
    goUnsignedInts = { fg = c.yellow }, goFloats = { fg = c.yellow }, goComplexes = { fg = c.yellow },
    goEscapeC = { fg = c.pink }, goFormatSpecifier = { fg = c.pink },
    -- Markdown (the lessons): Catppuccin's rainbow headings
    markdownH1 = { fg = c.red, bold = true }, markdownH2 = { fg = c.peach, bold = true },
    markdownH3 = { fg = c.yellow, bold = true }, markdownH4 = { fg = c.green, bold = true },
    markdownH5 = { fg = c.sapphire, bold = true }, markdownH6 = { fg = c.lavender, bold = true },
    markdownHeadingDelimiter = { fg = c.overlay1, bold = true }, markdownCode = { fg = c.teal },
    markdownCodeBlock = { fg = c.teal }, markdownCodeDelimiter = { fg = c.overlay0 },
    markdownBold = { fg = c.peach, bold = true }, markdownItalic = { fg = c.flamingo, italic = true },
    markdownLinkText = { fg = c.lavender, underline = true }, markdownUrl = { fg = c.rosewater, underline = true },
    markdownListMarker = { fg = c.mauve }, markdownOrderedListMarker = { fg = c.mauve },
    markdownBlockquote = { fg = c.overlay1 }, markdownRule = { fg = c.overlay0 },
    -- Diagnostics
    DiagnosticError = { fg = c.red }, DiagnosticWarn = { fg = c.yellow }, DiagnosticInfo = { fg = c.sky },
    DiagnosticHint = { fg = c.teal },
    DiagnosticVirtualTextError = { fg = c.red, bg = "#33293a" }, DiagnosticVirtualTextWarn = { fg = c.yellow, bg = "#34323b" },
    DiagnosticVirtualTextInfo = { fg = c.sky, bg = "#293141" }, DiagnosticVirtualTextHint = { fg = c.teal, bg = "#2a323f" },
    DiagnosticUnderlineError = { sp = c.red, undercurl = true }, DiagnosticUnderlineWarn = { sp = c.yellow, undercurl = true },
    DiagnosticUnderlineInfo = { sp = c.sky, undercurl = true }, DiagnosticUnderlineHint = { sp = c.teal, undercurl = true },
    -- Diffs and quickfix
    DiffAdd = { bg = "#323c3f" }, DiffChange = { bg = "#293042" }, DiffDelete = { bg = "#3e2e40" },
    DiffText = { bg = "#344257" }, diffAdded = { fg = c.green }, diffRemoved = { fg = c.red },
    qfFileName = { fg = c.blue }, qfLineNr = { fg = c.yellow },
    -- Explorer (netrw) and picker
    netrwDir = { fg = c.blue }, netrwClassify = { fg = c.blue }, netrwTreeBar = { fg = c.surface1 },
    netrwExe = { fg = c.green }, netrwSymLink = { fg = c.pink }, netrwLink = { fg = c.overlay1 },
    netrwMarkFile = { link = "Visual" }, netrwPlain = { fg = c.text },
    ExplorerNormal = { fg = c.subtext1, bg = c.mantle }, ExplorerCursorLine = { bg = c.surface0 },
    PickerMatch = { fg = c.blue, bold = true }, PickerSel = { bg = c.surface0, bold = true },
    PickerTitle = { fg = c.base, bg = c.mauve, bold = true },
    -- Status line blocks, one colour per mode (Catppuccin's lualine colours)
    StlNormal = { fg = c.mantle, bg = c.blue, bold = true }, StlInsert = { fg = c.mantle, bg = c.green, bold = true },
    StlVisual = { fg = c.mantle, bg = c.mauve, bold = true }, StlReplace = { fg = c.mantle, bg = c.red, bold = true },
    StlCommand = { fg = c.mantle, bg = c.peach, bold = true }, StlTerminal = { fg = c.mantle, bg = c.green, bold = true },
    StlMid = { fg = c.text, bg = c.surface0 }, StlFile = { fg = c.subtext1, bg = c.mantle },
    StlMod = { fg = c.peach, bg = c.mantle }, StlError = { fg = c.red, bg = c.mantle },
    StlWarn = { fg = c.yellow, bg = c.mantle },
  }
  for name, spec in pairs(groups) do api.nvim_set_hl(0, name, spec) end
  local ansi = { c.surface1, c.red, c.green, c.yellow, c.blue, c.pink, c.teal, c.subtext1,
    c.surface2, c.red, c.green, c.yellow, c.blue, c.pink, c.teal, c.subtext0 }
  for i, col in ipairs(ansi) do vim.g["terminal_color_" .. (i - 1)] = col end
end
theme()

for _, name in ipairs({ "Error", "Warn", "Info", "Hint" }) do
  fn.sign_define("DiagnosticSign" .. name, { text = "●", texthl = "Diagnostic" .. name })
end

---------------------------------------------------------------------------
-- Status line and buffer tab line
---------------------------------------------------------------------------
local modes = {
  n = { "NORMAL", "StlNormal" }, i = { "INSERT", "StlInsert" }, v = { "VISUAL", "StlVisual" },
  V = { "V-LINE", "StlVisual" }, ["\22"] = { "V-BLOCK", "StlVisual" }, c = { "COMMAND", "StlCommand" },
  R = { "REPLACE", "StlReplace" }, t = { "TERMINAL", "StlTerminal" }, s = { "SELECT", "StlVisual" },
  S = { "S-LINE", "StlVisual" },
}
-- The git branch, read straight from .git/HEAD ("" when detached). Starting git
-- on every buffer switch is slow on the container's mount.
local function git_branch(dir)
  local git = vim.fs.find(".git", { upward = true, path = dir })[1]
  if not git then return nil end
  local function first_line(path)
    local f = io.open(path)
    if not f then return nil end
    local line = f:read("*l")
    f:close()
    return line
  end
  if fn.isdirectory(git) == 0 then -- a worktree or submodule: .git is a file saying where the repo is
    local gitdir = (first_line(git) or ""):match("^gitdir: (.+)$")
    if not gitdir then return nil end
    git = gitdir:sub(1, 1) == "/" and gitdir or (vim.fs.dirname(git) .. "/" .. gitdir)
  end
  local head = first_line(git .. "/HEAD")
  return head and (head:match("^ref: refs/heads/(.+)$") or "")
end
api.nvim_create_autocmd({ "BufEnter", "FocusGained", "DirChanged" }, {
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then return end
    local dir = fn.expand("%:p:h")
    vim.b[ev.buf].git_branch = git_branch(fn.isdirectory(dir) == 1 and dir or fn.getcwd())
  end,
})
function _G.Statusline()
  local m = modes[api.nvim_get_mode().mode:sub(1, 1)] or { "?", "StlNormal" }
  local name = vim.bo.filetype == "netrw" and "Explorer" or fn.expand("%:~:.")
  if name == "" then name = "[No Name]" end
  local diag, e, w = {}, 0, 0
  for _, d in ipairs(vim.diagnostic.get(0)) do
    if d.severity == S.ERROR then e = e + 1 elseif d.severity == S.WARN then w = w + 1 end
  end
  if e > 0 then table.insert(diag, "%#StlError#● " .. e) end
  if w > 0 then table.insert(diag, "%#StlWarn#● " .. w) end
  local branch = vim.b.git_branch
  return table.concat({
    "%#", m[2], "# ", m[1], " ",
    branch and branch ~= "" and ("%#StlMid# " .. branch .. " ") or "",
    "%#StlFile# %<", name, vim.bo.modified and " %#StlMod#●" or "", vim.bo.readonly and " [RO]" or "",
    "%#StlFile#%=", table.concat(diag, "  "), "  ",
    vim.bo.filetype ~= "" and vim.bo.filetype .. "  " or "",
    "%#StlMid# %P ", "%#", m[2], "# %l:%c ",
  })
end
o.statusline = "%!v:lua.Statusline()"

function _G.Tabline()
  local cur = api.nvim_get_current_buf()
  local parts = {}
  for _, b in ipairs(listed_buffers()) do
    local name = fn.fnamemodify(api.nvim_buf_get_name(b), ":t")
    if name == "" then name = "[No Name]" end
    local sel = b == cur
    table.insert(parts, table.concat({
      sel and "%#TabLineMark#▎" or "%#TabLine# ",
      sel and "%#TabLineSel#" or "%#TabLine#", name, " ",
      vim.bo[b].modified and ((sel and "%#TabLineSelMod#" or "%#TabLineMod#") .. "● ") or "  ",
    }))
  end
  return table.concat(parts) .. "%#TabLineFill#"
end
o.showtabline = 2
o.tabline = "%!v:lua.Tabline()"

-- Briefly highlight yanked text
api.nvim_create_autocmd("TextYankPost", { callback = function() vim.highlight.on_yank() end })
