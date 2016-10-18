
local lfs = require "lfs"
local markdown = require "markdown"

local function walk(d, f)
	local stack = { d, push=table.insert, pop=table.remove }
	while true do
		d = stack:pop(1)
		if not d then break end
		for file in lfs.dir(d) do
			if file ~= "." and file ~= ".." then
				local full = d.."/"..file
				local a = assert(lfs.attributes(full))
				if f(full, file, a) == false then
					break
				end
				if a.mode == "directory" then
					stack:push(full)
				end
			end
		end
	end
end

local files = { }

walk(".", function(full, file, attrs)
	if attrs.mode == "file" and file:match("%.md$") then
		files[#files+1] = full
	elseif attrs.mode == "directory" then
		lfs.mkdir("../out/"..full)
	end
end)

local template = assert(assert(io.open("template.html")):read("*a"))

local function tplsubst(tpl, t)
	return (tpl:gsub("%$(%b{})", function(x)
		return t[x:sub(2, -2)]
	end))
end

--lfs.mkdir("../out")

for _, full in ipairs(files) do
	print(full)
	full = full:gsub("^%./", "")
	local base = full:match("(.+)/[^/]+$")
	print("base-before:",base)
	base = base and base:gsub("[^/]+", "..") or "."
	print("base-after:",base)
	print("css:",base.."/main.css")
	local out = "../"..full:gsub("%.md$", ".html")
	local text = assert(assert(io.open(full)):read("*a"))
	local title = assert(text:match("^%s*%#%s*([^\n]+)"), "no title given")
	local 
	text = tplsubst(template, {
		title=title,
		markdown=markdown(text),
		root=base,
	})
	local outf = assert(io.open(out, "w"))
	assert(outf:write(text))
	assert(outf:close())
end
