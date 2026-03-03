

ranks = {}

ranks.player = {}
ranks.boxes = {}
ranks.builder = {}
ranks.categories = {}

local wp = minetest.get_worldpath()

local fetch_file = function(filename, old, verify_ranks)
	local f = io.open(filename, "r")
	if not f then
		minetest.log("error", "failed to open " .. filename)
		return old
	end

	local fr = f:read("*all")
	f:close()

	local pl = minetest.parse_json(fr)
	if not pl then
		minetest.log("error", "failed to parse " .. filename)
		return old
	end

	if not verify_ranks then
		return pl
	end

	local tbl = {}

	for i = 1, 10 do
		if pl[tostring(i)] then
			tbl[i] = pl[tostring(i)]
		else
			minetest.log("error", filename .. " missing rank #" .. i)
			return old
		end
	end

	return tbl
end


ranks.fetch = function()
	-- alltime (original filenames, unchanged)
	ranks.player = fetch_file(wp .. "/top_players.json", ranks.player, true)
	ranks.box = fetch_file(wp .. "/top_boxes.json", ranks.box, true)
	ranks.builder = fetch_file(wp .. "/top_builders.json", ranks.builder, true)

	ranks.categories = fetch_file(wp .. "/category_series.json", ranks.categories, false)

	ranks.player_scores = fetch_file(wp .. "/player_scores.json", ranks.player_scores, false)
	ranks.builder_scores = fetch_file(wp .. "/builder_scores.json", ranks.builder_scores, false)
	ranks.box_scores = fetch_file(wp .. "/box_scores.json", ranks.box_scores, false)

	-- monthly
	ranks.player_monthly = fetch_file(wp .. "/top_players_monthly.json", ranks.player_monthly, false)
	ranks.box_monthly = fetch_file(wp .. "/top_boxes_monthly.json", ranks.box_monthly, false)
	ranks.builder_monthly = fetch_file(wp .. "/top_builders_monthly.json", ranks.builder_monthly, false)
	ranks.player_scores_monthly = fetch_file(wp .. "/player_scores_monthly.json", ranks.player_scores_monthly, false)
	ranks.builder_scores_monthly = fetch_file(wp .. "/builder_scores_monthly.json", ranks.builder_scores_monthly, false)
	ranks.box_scores_monthly = fetch_file(wp .. "/box_scores_monthly.json", ranks.box_scores_monthly, false)

	-- yearly
	ranks.player_yearly = fetch_file(wp .. "/top_players_yearly.json", ranks.player_yearly, false)
	ranks.box_yearly = fetch_file(wp .. "/top_boxes_yearly.json", ranks.box_yearly, false)
	ranks.builder_yearly = fetch_file(wp .. "/top_builders_yearly.json", ranks.builder_yearly, false)
	ranks.player_scores_yearly = fetch_file(wp .. "/player_scores_yearly.json", ranks.player_scores_yearly, false)
	ranks.builder_scores_yearly = fetch_file(wp .. "/builder_scores_yearly.json", ranks.builder_scores_yearly, false)
	ranks.box_scores_yearly = fetch_file(wp .. "/box_scores_yearly.json", ranks.box_scores_yearly, false)

	minetest.after(300, ranks.fetch)
end

function ranks.get(key, window)
	if window == "monthly" then return ranks[key .. "_monthly"]
	elseif window == "yearly" then return ranks[key .. "_yearly"]
	end
	return ranks[key]
end

minetest.after(0, ranks.fetch)
