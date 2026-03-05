

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

	-- auto series
	ranks.auto_series = fetch_file(wp .. "/auto_series.json", ranks.auto_series, false)
	if ranks.auto_series then
		ranks.sync_auto_series()
	end

	minetest.after(300, ranks.fetch)
end

local function lists_equal(a, b)
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

function ranks.sync_auto_series()
	local all_series = db.series_get_series()
	local name_to_id = {}
	for _, s in ipairs(all_series) do
		name_to_id[s.name] = s.id
	end

	for _, entry in pairs(ranks.auto_series) do
		local name = entry.name
		local new_ids = entry.box_ids or {}

		-- find or create series
		local series_id = name_to_id[name]
		if not series_id then
			series_id = db.series_create(name)
			if not series_id then
				minetest.log("error", "ranks: failed to create auto series: " .. name)
				goto continue
			end
			name_to_id[name] = series_id
		end

		-- ensure meta has auto=true and type=random_access
		local smeta = db.series_get_meta(series_id)
		if smeta then
			local changed = false
			if not smeta.meta.auto then
				smeta.meta.auto = true
				changed = true
			end
			if smeta.meta.type ~= db.RANDOM_ACCESS_TYPE then
				smeta.meta.type = db.RANDOM_ACCESS_TYPE
				changed = true
			end
			if changed then
				db.series_set_meta(series_id, smeta)
			end
		end

		-- compare current box list with new
		local current = db.series_get_boxes(series_id)
		if not lists_equal(current, new_ids) then
			db.series_clear_boxes(series_id)
			for order, box_id in ipairs(new_ids) do
				db.series_insert_box(series_id, box_id, order)
			end
			minetest.log("action", "ranks: updated auto series '" ..
				name .. "' (id=" .. series_id .. ") with " ..
				#new_ids .. " boxes")
		end

		::continue::
	end
end

function ranks.get(key, window)
	if window == "monthly" then return ranks[key .. "_monthly"]
	elseif window == "yearly" then return ranks[key .. "_yearly"]
	end
	return ranks[key]
end

minetest.after(0, ranks.fetch)
