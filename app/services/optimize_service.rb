class OptimizeService

	def self.call(players)
		new.call(players)
	end

	def call(players)
		@all_lineups = {
			'ol' => [],
			'sl' => [],
			'rl' => [],
			'bl' => []
		}

		@rb_limit = 30
		@wr_limit = 50
		@qb_limit = 20
		@te_limit = 30
		@k_limit = 30
		@def_limit = 20

		@all_players = player_creator(players)
		@valid_price = valid_price_creator
		@valid_score = valid_score_creator
		@rw_combos = rw_combo_creator(rb_combo_creator, wr_combo_creator)
		@all_players['RB'] = nil
		@all_players['WR'] = nil
		@kd_combos = kd_combo_creator
		@all_players['K'] = nil
		@all_players['DEF'] = nil

		rw_helper

		return @all_lineups
	end

	private

	attr_accessor :all_lineups, :all_players, :rb_combos, :wr_combos, :valid_checker
		
		#create object of player instances
		def player_creator(players)
			def pc_helper(pos, players, pos_limit)
				pos_array = []
				count = 0
				players[pos]['Rankings'].each do |player|
					break if count > pos_limit
					player_db = Player.find_by(name: player['name'])
					if player_db
						insert_check = true
						new_player = Position.new(pos, player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
						for i in 0...pos_array.count do
							if new_player.best_score.to_i > pos_array[i].best_score
								pos_array.insert(i, new_player)
								insert_check = false
								break
							end
						end
						if insert_check
							pos_array << new_player
						end
						count += 1
					end
					puts "PLAYER CREATOR"
				end
				return pos_array
			end

			player_obj = {
				"QB" => pc_helper("QB", players, @qb_limit),
				"RB" => pc_helper("RB", players, @rb_limit),
				"WR" => pc_helper("WR", players, @wr_limit),
				"TE" => pc_helper("TE", players, @te_limit),
				"K" => pc_helper("K", players, @k_limit),
				"DEF" => pc_helper("DEF", players, @def_limit)
			}

			return player_obj
		end

		#pre determine all RB & WR combinations
		def rb_combo_creator
			rb_combo_array = []
			for i in 0...@all_players['RB'].count do
				for j in (i+1)...@all_players['RB'].count do
					insert_check = true
					for k in 0...rb_combo_array.count do
						if (@all_players['RB'][i].best_score.to_i + @all_players['RB'][j].best_score.to_i) > (rb_combo_array[k][0].best_score.to_i + rb_combo_array[k][1].best_score.to_i)
							rb_combo_array.insert(k, [@all_players['RB'][i], @all_players['RB'][j]])
							insert_check = false
							break
						end
					end
					if insert_check
						rb_combo_array << [@all_players['RB'][i], @all_players['RB'][j]]
					end
					puts "RB COMBO CREATOR"
				end
			end

			return rb_combo_array
		end
		def wr_combo_creator
			wr_combo_array = []
			for i in 0...@all_players['WR'].count do
				for j in (i+1)...@all_players['WR'].count do
					for k in (j+1)...@all_players['WR'].count do
						insert_check = true
						for n in 0...wr_combo_array.count do
							if (@all_players['WR'][i].best_score + @all_players['WR'][j].best_score + @all_players['WR'][k].best_score) > (wr_combo_array[n][0].best_score + wr_combo_array[n][1].best_score + wr_combo_array[n][2].best_score)
								wr_combo_array.insert(n, [@all_players['WR'][i], @all_players['WR'][j], @all_players['WR'][k]])
								insert_check = false
								break
							end
						end
						if insert_check
							wr_combo_array << [@all_players['WR'][i], @all_players['WR'][j], @all_players['WR'][k]]
						end
					puts "WR COMBO CREATOR"
					end
				end
			end

			return wr_combo_array
		end
		def rw_combo_creator(rb_combos, wr_combos)
			rw_combo_array = []
			for i in 0...rb_combos.count do
				for j in 0...wr_combos.count do
					if validator(nil, [rb_combos[i][0], rb_combos[i][1], wr_combos[j][0], wr_combos[j][1], wr_combos[j][2]], "QB")
						rw_combo_array << [rb_combos[i][0], rb_combos[i][1], wr_combos[j][0], wr_combos[j][1], wr_combos[j][2]]
					end
					puts "RW COMBO CREATOR"
				end
			end
			return rw_combo_array
		end
		def kd_combo_creator
			kd_combo_array = []
			@all_players['K'].each do |k|
				@all_players['DEF'].each do |de|
					insert_check = true
					for i in 0...kd_combo_array.count do
						if (k.best_score.to_i + de.best_score.to_i) > (kd_combo_array[i][0].best_score.to_i + kd_combo_array[i][1].best_score.to_i)
							kd_combo_array.insert(i, [k, de])
							insert_check = false
							break
						end
					end
					if insert_check
						kd_combo_array << [k, de]
					end
					puts "KD COMBO CREATOR"
				end
			end
			return kd_combo_array
		end
		# def tkd_combo_creator
		# 	tkd_combo_array = []
		# 	@all_players['TE'].each do |te|
		# 		@all_players['K'].each do |k|
		# 			@all_players['DEF'].each do |de|
		# 				insert_check = true
		# 				if validator(nil, [te,k,de], 'RW')
		# 					for i in 0...tkd_combo_array.count do
		# 						if (te.best_score.to_i + k.best_score.to_i + de.best_score.to_i) > (tkd_combo_array[i][0].best_score.to_i + tkd_combo_array[i][1].best_score.to_i + tkd_combo_array[i][2].best_score.to_i)
		# 							tkd_combo_array.insert(i, [te, k, de])
		# 							insert_check = false
		# 							break
		# 						end
		# 					end
		# 					if insert_check
		# 						tkd_combo_array << [te, k, de]
		# 					end
		# 				end
		# 				puts "TKD COMBO CREATOR"
		# 			end
		# 		end
		# 	end
		# 	return tkd_combo_array
		# end

		def valid_price_creator
			def valid_helper(pos)
				pos_min = nil
				@all_players[pos].each do |player|
					if pos_min
						if player.price < pos_min
							pos_min = player.price
						end	
					else
						pos_min = player.price
					end
				end
				return pos_min
			end

			valid_price_obj = {
				"QB" => valid_helper("QB"),
				"TE" => valid_helper("TE"),
				 "K" => (valid_helper("K") + valid_helper("DEF"))
			}

			valid_price_obj["TE"] += valid_price_obj['K']
			valid_price_obj['QB'] += valid_price_obj['TE']

			return valid_price_obj
		end

		def valid_score_creator
			def valid_helper(pos)
				ol_max = nil
				@all_players[pos].each do |player|
					if ol_max
						if player.avg_score > ol_max
							ol_max = player.avg_score
						end	
					else
						ol_max = player.avg_score
					end
				end
				rl_max = nil
				@all_players[pos].each do |player|
					if rl_max
						if player.max_score > rl_max
							rl_max = player.max_score
						end	
					else
						rl_max = player.max_score
					end
				end

				sl_max = nil
				@all_players[pos].each do |player|
					if sl_max
						if player.min_score > sl_max
							sl_max = player.min_score
						end	
					else
						sl_max = player.min_score
					end
				end

				helper_obj = {
					'ol' => ol_max,
					'rl' => rl_max,
					'sl' => sl_max,
					'bl' => @all_players[pos][0].best_score
				}

				return helper_obj
			end

			valid_score_obj = { 
				"QB" => valid_helper('QB'),
				"TE" => valid_helper('TE'),
				"K" => valid_helper('K'),
				"DEF" => valid_helper('DEF')
			}

			valid_score_obj['K']['ol'] += valid_score_obj['DEF']['ol']
			valid_score_obj['K']['rl'] += valid_score_obj['DEF']['rl']
			valid_score_obj['K']['sl'] += valid_score_obj['DEF']['sl']
			valid_score_obj['K']['bl'] += valid_score_obj['DEF']['bl']

			valid_score_obj['TE']['ol'] += valid_score_obj['K']['ol']
			valid_score_obj['TE']['rl'] += valid_score_obj['K']['rl']
			valid_score_obj['TE']['sl'] += valid_score_obj['K']['sl']
			valid_score_obj['TE']['bl'] += valid_score_obj['K']['bl']

			valid_score_obj['QB']['ol'] += valid_score_obj['TE']['ol']
			valid_score_obj['QB']['rl'] += valid_score_obj['TE']['rl']
			valid_score_obj['QB']['sl'] += valid_score_obj['TE']['sl']
			valid_score_obj['QB']['bl'] += valid_score_obj['TE']['bl']

			return valid_score_obj
		end

		def validator(lineup, player_array, val_pos = nil)
			if lineup
				valid_price = lineup.price.to_i
				valid_ol = lineup.avg_score.to_i
				valid_rl = lineup.max_score.to_i
				valid_sl = lineup.min_score.to_i
				valid_bl = lineup.best_score.to_i
			else
				valid_price = 0
				valid_ol = 0
				valid_rl = 0
				valid_sl = 0
				valid_bl = 0
			end

			if player_array
				player_array.each do |ply|
					valid_price += ply.price.to_i
					valid_ol += ply.avg_score.to_i
					valid_rl += ply.max_score.to_i
					valid_sl += ply.min_score.to_i
					valid_bl += ply.best_score.to_i
				end
			end
			
			if val_pos
				valid_price += @valid_price[val_pos].to_i
			end

			if valid_price > 60000
				return false
			end
			if @all_lineups['ol'].count < 12
				return true
			end
			
			if val_pos
				valid_ol += @valid_score[val_pos]['ol'].to_i
				valid_rl += @valid_score[val_pos]['rl'].to_i
				valid_sl += @valid_score[val_pos]['sl'].to_i
				valid_bl += @valid_score[val_pos]['bl'].to_i
			end

			if valid_ol > @all_lineups['ol'].last.avg_score
				return true
			end
			if valid_rl > @all_lineups['rl'].last.max_score
				return true
			end
			if valid_sl > @all_lineups['sl'].last.min_score
				return true
			end
			if valid_bl > @all_lineups['bl'].last.best_score
				return true
			end

			return false
		end

		#BEGIN LINEUP CREATIONS
		def rw_helper
			for i in 0...@rw_combos.count do
				loading = ((i.to_f / @rw_combos.count.to_f)*100).round(2)
				puts i.to_s + "/" + @rw_combos.count.to_s + "--" + loading.to_s + "%"
				rw_lineup = Lineup.new
				for j in 0...@rw_combos[i].count do
					rw_lineup.add_player(@rw_combos[i][j])
				end
				if validator(rw_lineup, [], 'QB')
					qb_helper(rw_lineup)
				end
				rw_lineup = nil
			end
		end

		def qb_helper(qb_helper_lineup)
			qb_lineup = Lineup.new
			qb_helper_lineup.roster.each do |ply|
				qb_lineup.add_player(ply)
			end
			@all_players['QB'].each do |qb|
				if validator(qb_lineup, [qb], 'TE')
					te_helper(qb_lineup, qb)
				end
			end
			qb_lineup = nil
			qb_helper_lineup = nil
		end

		def te_helper(te_helper_lineup, player)
			te_lineup = Lineup.new
			te_lineup.add_player(player)
			te_helper_lineup.roster.each do |ply|
				te_lineup.add_player(ply)
			end
			@all_players['TE'].each do |te|
				if validator(te_lineup, [te], 'K')
					kd_helper(te_lineup, te)
				end
			end
			te_lineup = nil
			te_helper_lineup = nil
		end

		def kd_helper(kd_helper_lineup, player)
			kd_lineup = Lineup.new
			kd_helper_lineup.roster.each do |ply|
				kd_lineup.add_player(ply)
			end
			kd_lineup.add_player(player)
			for i in 0...@kd_combos.count do
				if validator(kd_lineup, [@kd_combos[i][0], @kd_combos[i][1]])
					final_helper(kd_lineup, @kd_combos[i][0], @kd_combos[i][1])
					break
				end
			end
			kd_lineup = nil
			kd_helper_lineup = nil
		end

		# def tkd_helper(tkd_helper_lineup, player)
		# 	tkd_lineup = Lineup.new
		# 	tkd_lineup.add_player(player)
		# 	tkd_helper_lineup.roster.each do |ply|
		# 		tkd_lineup.add_player(ply)
		# 	end
		# 	for i in 0...@tkd_combos.count do
		# 		if validator(tkd_lineup, [@tkd_combos[i][0], @tkd_combos[i][1], @tkd_combos[i][2]])
		# 			final_helper(tkd_lineup, @tkd_combos[i][0], @tkd_combos[i][1], @tkd_combos[i][2])
		# 			break
		# 		end
		# 	end
		# 	tkd_lineup = nil
		# 	tkd_helper_lineup = nil
		# end

		def final_helper(final_helper_lineup, player1, player2)
			final_lineup = Lineup.new
			final_helper_lineup.roster.each do |ply|
				final_lineup.add_player(ply)
			end
			final_lineup.add_player(player1)
			final_lineup.add_player(player2)

			ol_insert_check = true
			if @all_lineups['ol'].count < 12
				for i in 0...@all_lineups['ol'].count
					if final_lineup.avg_score > @all_lineups['ol'][i].avg_score
						@all_lineups['ol'].insert(i, final_lineup)
						puts final_lineup.players_used
						ol_insert_check = false
						break
					end
				end
				if ol_insert_check
					@all_lineups['ol'] << final_lineup
					puts final_lineup.players_used
					ol_insert_check = false
				end
			else
				if final_lineup.avg_score > @all_lineups['ol'][5].avg_score
					for i in 0...@all_lineups['ol'].count do
						if final_lineup.avg_score > @all_lineups['ol'][i].avg_score
							@all_lineups['ol'].insert(i, final_lineup)
							@all_lineups['ol'].pop
							puts final_lineup.players_used
							insert_check = false
							break
						end
					end
				end
			end

			rl_insert_check = true
			if @all_lineups['rl'].count < 12
				for i in 0...@all_lineups['rl'].count
					if final_lineup.max_score > @all_lineups['rl'][i].max_score
						@all_lineups['rl'].insert(i, final_lineup)
						puts final_lineup.players_used
						rl_insert_check = false
						break
					end
				end
				if rl_insert_check
					@all_lineups['rl'] << final_lineup
					puts final_lineup.players_used
					rl_insert_check = false
				end
			else
				if final_lineup.max_score > @all_lineups['rl'][5].max_score
					for i in 0...@all_lineups['rl'].count do
						if final_lineup.max_score > @all_lineups['rl'][i].max_score
							@all_lineups['rl'].insert(i, final_lineup)
							@all_lineups['rl'].pop
							puts final_lineup.players_used
							rl_insert_check = false
							break
						end
					end
				end
			end

			sl_insert_check = true
			if @all_lineups['sl'].count < 12
				for i in 0...@all_lineups['sl'].count
					if final_lineup.min_score > @all_lineups['sl'][i].min_score
						@all_lineups['sl'].insert(i, final_lineup)
						puts final_lineup.players_used
						sl_insert_check = false
						break
					end
				end
				if sl_insert_check
					@all_lineups['sl'] << final_lineup
					puts final_lineup.players_used
					sl_insert_check = false
				end
			else
				if final_lineup.min_score > @all_lineups['sl'][5].min_score
					for i in 0...@all_lineups['sl'].count do
						if final_lineup.min_score > @all_lineups['sl'][i].min_score
							@all_lineups['sl'].insert(i, final_lineup)
							@all_lineups['sl'].pop
							puts final_lineup.players_used
							sl_insert_check = false
							break
						end
					end
				end
			end

			bl_insert_check = true
			if @all_lineups['bl'].count < 12
				for i in 0...@all_lineups['bl'].count
					if final_lineup.best_score > @all_lineups['bl'][i].best_score
						@all_lineups['bl'].insert(i, final_lineup)
						puts final_lineup.players_used
						bl_insert_check = false
						break
					end
				end
				if bl_insert_check
					@all_lineups['bl'] << final_lineup
					puts final_lineup.players_used
					bl_insert_check = false
				end
			else
				if final_lineup.best_score > @all_lineups['bl'][5].best_score
					for i in 0...@all_lineups['bl'].count do
						if final_lineup.best_score > @all_lineups['bl'][i].best_score
							@all_lineups['bl'].insert(i, final_lineup)
							@all_lineups['bl'].pop
							puts final_lineup.players_used
							bl_insert_check = false
							break
						end
					end
				end
			end

			if ol_insert_check && rl_insert_check && sl_insert_check && bl_insert_check
				final_lineup = nil
			end
			final_helper_lineup = nil
		end	
end