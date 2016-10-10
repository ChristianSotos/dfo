class OptimizeService

	def self.call(players)
		new.call(players)
	end

	def call(players)
		@all_lineups = {
			'bl' => [],
			'ol' => [],
			'sl' => [],
			'rl' => []
		}


		@rb_limit = 20
		@wr_limit = 40
		@qb_limit = 20
		@te_limit = 20
		@k_limit = 30
		@def_limit = 20

		@lineup_limit = 20

		@qb_exposure = 0.25
		@rb_exposure = 0.4
		@wr_exposure = 0.4
		@te_exposure = 0.25
		@k_exposure = 0.5
		@de_exposure = 0.5

		@exposure_limit = {
			'QB' => ((@lineup_limit.to_f*4.to_f) * @qb_exposure.to_f).to_i,
			'RB' => ((@lineup_limit.to_f*4.to_f) * @rb_exposure.to_f).to_i,
			'WR' => ((@lineup_limit.to_f*4.to_f) * @wr_exposure.to_f).to_i,
			'TE' => ((@lineup_limit.to_f*4.to_f) * @te_exposure.to_f).to_i,
			'K' => ((@lineup_limit.to_f*4.to_f) * @k_exposure.to_f).to_i,
			'DEF' => ((@lineup_limit.to_f*4.to_f) * @de_exposure.to_f).to_i
		}

		@all_players = player_creator(players)
		@valid_price = valid_price_creator
		@valid_score = valid_score_creator
		@rw_combos = rw_combo_creator(rb_combo_creator, wr_combo_creator)
		@all_players['RB'] = nil
		@all_players['WR'] = nil
		@kd_combos = kd_combo_creator
		@all_players['K'] = nil
		@all_players['DEF'] = nil

		@kd_offset = 0

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
				 "K" => valid_helper("K"),
				 "DEF" => valid_helper("DEF")
			}

			valid_price_obj['K'] += valid_price_obj['DEF']
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

		def validator(lineup_array, player_array, val_pos = nil)
			valid_price = 0
			valid_bl = 0
			valid_ol = 0
			valid_rl = 0
			valid_sl = 0
			valid_exposure = true

			if lineup_array
				lineup_array.each do |ply|
					if ply.exposure >= @exposure_limit[ply.position]
						valid_exposure = false
					end
					valid_price += ply.price.to_i
					valid_bl += ply.best_score.to_i
					valid_ol += ply.avg_score.to_i
					valid_rl += ply.max_score.to_i
					valid_sl += ply.min_score.to_i
				end
			end

			if player_array
				player_array.each do |ply|
					if ply.exposure >= @exposure_limit[ply.position]
						valid_exposure = false
					end
					valid_price += ply.price.to_i
					valid_bl += ply.best_score.to_i
					valid_ol += ply.avg_score.to_i
					valid_rl += ply.max_score.to_i
					valid_sl += ply.min_score.to_i
				end
			end
			
			if val_pos
				valid_price += @valid_price[val_pos].to_i
				valid_ol += @valid_score[val_pos]['ol'].to_i
				valid_rl += @valid_score[val_pos]['rl'].to_i
				valid_sl += @valid_score[val_pos]['sl'].to_i
				valid_bl += @valid_score[val_pos]['bl'].to_i
			end

			if valid_price > 60000
				return false
			end

			if valid_exposure
				if @all_lineups['ol'].count < @lineup_limit || @all_lineups['bl'].count < @lineup_limit || @all_lineups['rl'].count < @lineup_limit || @all_lineups['sl'].count < @lineup_limit
					return true
				end
			end

			if valid_bl > @all_lineups['bl'].last.best_score
				return true
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

			return false
		end

		def exposure_update(new_lineup, old_lineup=nil)
			if old_lineup
				old_lineup.roster.each do |ply|
					ply.exposure -= 1
				end
			end

			if new_lineup
				new_lineup.roster.each do |ply|
					ply.exposure += 1
				end
			end
		end

		#BEGIN LINEUP CREATIONS
		def rw_helper
			for i in 0...@rw_combos.count do
				loading = ((i.to_f / @rw_combos.count.to_f)*100).round(2)
				puts i.to_s + "/" + @rw_combos.count.to_s + "--" + loading.to_s + "%"

				if validator(@rw_combos[i], [], 'QB')
					qb_helper(@rw_combos[i])
				end
				rw_lineup = nil
			end
		end

		def qb_helper(qb_helper_lineup)
			qb_lineup = [].concat(qb_helper_lineup)
			@all_players['QB'].each do |qb|
				if validator(qb_lineup, [qb], 'TE')
					te_helper(qb_lineup, qb)
				end
			end
			qb_lineup = nil
			qb_helper_lineup = nil
		end

		def te_helper(te_helper_lineup, player)
			te_lineup = [player].concat(te_helper_lineup)
			@all_players['TE'].each do |te|
				if validator(te_lineup, [te], 'K')
					insert_check = kd_helper(te_lineup, te)
					if insert_check
						break
					end
				end
			end
			te_lineup = nil
			te_helper_lineup = nil
			return false
		end

		def kd_helper(kd_helper_lineup, player)
			kd_lineup = [].concat(kd_helper_lineup).concat([player])
			i = @kd_offset%2
			while i < @kd_combos.count
				if validator(kd_lineup, [@kd_combos[i][0], @kd_combos[i][1]])
					@kd_offset += 1
					return final_helper(kd_lineup, @kd_combos[i][0], @kd_combos[i][1])
				end
				i += 2
			end
			kd_helper_lineup = nil
			kd_lineup = nil
			return false
		end
		# def de_helper(de_helper_lineup, player1, player2)
		# 	de_lineup = Lineup.new
		# 	de_helper_lineup.roster.each do |ply|
		# 		de_lineup.add_player(ply)
		# 	end
		# 	de_lineup.add_player(player1)
		# 	de_lineup.add_player(player2)
		# 	@all_players['DEF'].each do |de|
		# 		if validator(de_lineup, [de])
		# 			final_helper(de_lineup, de)
		# 			break
		# 		end
		# 	end
		# 	de_lineup = nil
		# 	de_helper_lineup = nil
		# end

		def final_helper(final_helper_lineup, player1, player2)
			valid_exposure = true
			exposure_players = []
			
			final_lineup = Lineup.new
			final_helper_lineup.each do |ply|
				if ply.exposure >= @exposure_limit[ply.position]
					valid_exposure = false
					exposure_players << ply
				end
				final_lineup.add_player(ply)
			end
			final_lineup.add_player(player1)
			final_lineup.add_player(player2)

			if valid_exposure
				insert_check = lineup_insertion(final_lineup)

				if insert_check
					return true
				else
					final_lineup = nil
					return false
				end
			else
				return exposure_helper(final_lineup, exposure_players)
			end

		end

		def lineup_insertion(insert_lineup)
			insert_check = {
				'bl' => true,
				'ol' => true,
				'rl' => true,
				'sl' => true
			}

			removed_lineup = nil
			i = 0
			
			@all_lineups.each do |category, arr|
				if !arr.include?(insert_lineup)
					for i in 0...arr.count do
						if insert_lineup.get_scores[category] > arr[i].get_scores[category]
							@all_lineups[category].insert(i, insert_lineup)
							if arr.count > @lineup_limit
								exposure_update(insert_lineup, @all_lineups[category].last)
								removed_lineup = @all_lineups[category].pop
							else
								exposure_update(insert_lineup)
							end
							puts insert_lineup.players_used
							insert_check[category] = false
							break
						end
					end
				end
			end

			@all_lineups.each do |category, arr|
				if arr.count < @lineup_limit && insert_check[category] && !arr.include?(insert_lineup)
					exposure_update(insert_lineup)
					@all_lineups[category] << insert_lineup
					puts insert_lineup.players_used
					insert_check[category] = false
				end
			end

			if removed_lineup
				lineup_insertion(removed_lineup)
			end

			if insert_check['bl'] && insert_check['ol'] && insert_check['rl'] && insert_check['sl'] 
				return false
			else 
				return true
			end
		end

		def exposure_helper(insert_lineup, players)
			insert_check = false

			removed_lineup = nil

			@all_lineups.each do |category, arr|
				if !arr.include?(insert_lineup)
					i = arr.count - 1
					while i >= 0
						player_check = true
						players.each do |ply|
							if !@all_lineups[category][i].roster.include?(ply)
								player_check = false
								break
							end
						end
						if player_check
							if insert_lineup.get_scores[category] > arr[i].get_scores[category]
								exposure_update(insert_lineup, @all_lineups[category][i])
								removed_lineup = @all_lineups[category][i]
								@all_lineups[category][i] = insert_lineup
								puts insert_lineup.players_used
								insert_check = true
								j = i
								while j > 0
									if @all_lineups[category][j].get_scores[category] > @all_lineups[category][j-1].get_scores[category]
										temp = @all_lineups[category][j]
										@all_lineups[category][j] = @all_lineups[category][j-1]
										@all_lineups[category][j-1] = temp
									else
										j = 0
									end
									j -= 1
								end
							end
							i = 0
						end
						i -= 1
					end
				end
			end

			if removed_lineup
				exposure_helper(removed_lineup, players)
			end

			return insert_check
		end
end