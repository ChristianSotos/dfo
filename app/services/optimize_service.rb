class OptimizeService

	def self.call(players)
		new.call(players)
	end

	def call(players)
		@all_lineups = {
			'ol' => [],
			'sl' => [],
			'rl' => []
		}
		
		@rb_limit = 20
		@wr_limit = 50
		@qb_limit = 30
		@te_limit = 30
		@k_limit = 32
		@def_limit = 32

		@all_players = player_creator(players)
		@valid_checker = valid_creator
		@rb_combos = rb_combo_creator
		@wr_combos = wr_combo_creator
		@rw_combos = rw_combo_creator
		@valid_score = valid_score_helper

		rw_helper

		#puts @all_lineups.count
		return @all_lineups
	end

	private

	attr_accessor :all_lineups, :all_players, :rb_combos, :wr_combos, :valid_checker
		
		#create object of player instances
		def player_creator(players)
			def pc_helper(pos, players)
				pos_array = []
				players[pos]['Rankings'].each do |player|
					player_db = Player.find_by(name: player['name'])
					if player_db
						insert_check = true
						for i in 0...pos_array.count do
							if player['ppr'].to_i > pos_array[i].avg_score
								pos_array.insert(i, Position.new(pos, player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price))
								insert_check = false
								break
							end
						end
						if insert_check
							pos_array << Position.new(pos, player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
						end
					end
				end
				return pos_array
			end

			player_obj = {
				"QB" => pc_helper("QB", players),
				"RB" => pc_helper("RB", players),
				"WR" => pc_helper("WR", players),
				"TE" => pc_helper("TE", players),
				"K" => pc_helper("K", players),
				"DEF" => pc_helper("DEF", players)
			}

			return player_obj
		end

		#pre determine all RB & WR combinations
		def rb_combo_creator
			rb_array = []
			rb_combo_array = []
			@all_players['RB'].each do |player|
				insert_check = true
				for i in 0...rb_array.count do
					if player.avg_score > rb_array[i].avg_score
						rb_array.insert(i, player)
						insert_check = false
						break
					end
				end
				if insert_check
					rb_array << player
				end
			end


			for i in 0...@rb_limit do
				for j in (i+1)...@rb_limit do
					insert_check = true
					for k in 0...rb_combo_array.count do
						if (rb_array[i].avg_score + rb_array[j].avg_score) > (rb_combo_array[k][0].avg_score + rb_combo_array[k][1].avg_score)
							rb_combo_array.insert(k, [rb_array[i], rb_array[j]])
							insert_check = false
							break
						end
					end
					if insert_check
						rb_combo_array << [rb_array[i], rb_array[j]]
					end
				end
			end

			return rb_combo_array
		end
		def wr_combo_creator
			wr_array = []
			wr_combo_array = []
			@all_players['WR'].each do |player|
				insert_check = true
				for i in 0...wr_array.count do
					if player.avg_score > wr_array[i].avg_score
						wr_array.insert(i, player)
						insert_check = false
						break
					end
				end
				if insert_check
					wr_array << player
				end
			end

			for i in 0...@wr_limit do
				for j in (i+1)...@wr_limit do
					for k in (j+1)...@wr_limit do
						insert_check = true
						for n in 0...wr_combo_array.count do
							if (wr_array[i].avg_score + wr_array[j].avg_score + wr_array[k].avg_score) > (wr_combo_array[n][0].avg_score + wr_combo_array[n][1].avg_score + wr_combo_array[n][2].avg_score)
								wr_combo_array.insert(n, [wr_array[i], wr_array[j], wr_array[k]])
								insert_check = false
								break
							end
						end
						if insert_check
							wr_combo_array << [wr_array[i], wr_array[j], wr_array[k]]
						end
					end
				end
			end

			return wr_combo_array
		end
		def rw_combo_creator
			rw_combo_array = []
			for i in 0...@rb_combos.count do
				for j in 0...@wr_combos.count do
					if (@rb_combos[i][0].price.to_i + @rb_combos[i][1].price.to_i + @wr_combos[j][0].price.to_i + @wr_combos[j][1].price.to_i + @wr_combos[j][2].price.to_i + valid_checker['QB']) <= 60000
						rw_combo_array << [@rb_combos[i][0], @rb_combos[i][1], @wr_combos[j][0], @wr_combos[j][1], @wr_combos[j][2]]
					end
					# puts rw_combo_array.count
				end
			end
			return rw_combo_array
		end

		#create object of minimum possible price moving forward from a given position
		def valid_creator
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

			valid_checker_obj = {
				"QB" => valid_helper("QB"),
				"TE" => valid_helper("TE"),
				"K" => valid_helper("K"),
				"DEF" => valid_helper("DEF")
			}

			valid_checker_obj['K'] += valid_checker_obj['DEF']
			valid_checker_obj['TE'] += valid_checker_obj['K']
			valid_checker_obj['QB'] += valid_checker_obj['TE']


			return valid_checker_obj
		end

		def valid_score_helper
			valid_score_obj = { 
				"QB" => @all_players['QB'][0].avg_score,
				"TE" => @all_players['TE'][0].avg_score,
				"K" => @all_players['K'][0].avg_score,
				"DEF" => @all_players['DEF'][0].avg_score
			}
			valid_score_obj['K'] += valid_score_obj['DEF']
			valid_score_obj['TE'] += valid_score_obj['K']
			valid_score_obj['QB'] += valid_score_obj['TE']

			puts valid_score_obj
			return valid_score_obj
		end

		#BEGIN LINEUP CREATIONS
		def rw_helper
			for i in 0...@rw_combos.count do
				rw_lineup = Lineup.new
				for j in 0...@rw_combos[i].count do
					rw_lineup.add_player(@rw_combos[i][j])
				end
				if ((rw_lineup.price.to_i + valid_checker['QB']) <= 60000)
					if @all_lineups['ol'].count < 6
						qb_helper(rw_lineup)
					else
						if (rw_lineup.avg_score.to_i + @valid_score['QB']) > @all_lineups['ol'][5].avg_score
							qb_helper(rw_lineup)
						end
					end
				end
				rw_lineup = nil
			end
		end

		def qb_helper(qb_helper_lineup)
			qb_lineup = Lineup.new
			qb_helper_lineup.roster.each do |ply|
				qb_lineup.add_player(ply)
			end
			# if (qb_lineup.price.to_i + @valid_checker['QB']) <= 60000
			count = 0
			@all_players['QB'].each do |qb|
				break if count > @qb_limit
				if (qb_lineup.price.to_i + qb.price.to_i + @valid_checker['TE']) <= 60000
					if @all_lineups['ol'].count < 6
						te_helper(qb_lineup, qb)
					else
						if (qb_lineup.avg_score.to_i + qb.avg_score.to_i + @valid_score['TE']) > @all_lineups['ol'][5].avg_score
							te_helper(qb_lineup, qb)
						else
							puts "QB SCORE INVALID"
						end
					end
				else
					puts "QB PRICE INVALID"
				end
				count += 1
			end
			qb_lineup = nil
			qb_helper_lineup = nil
		end

		def te_helper(te_helper_lineup, player)
			te_lineup = Lineup.new
			te_helper_lineup.roster.each do |ply|
				te_lineup.add_player(ply)
			end
			te_lineup.add_player(player)
			# if (te_lineup.price.to_i + @valid_checker['TE']) <= 60000
			count = 0
			@all_players['TE'].each do |te|

				break if count > @te_limit
				if (te_lineup.price.to_i + te.price.to_i + @valid_checker['K']) <= 60000
					if @all_lineups['ol'].count < 6
						k_helper(te_lineup, te)
					else
						if (te_lineup.avg_score.to_i + te.avg_score.to_i + @valid_score['K']) > @all_lineups['ol'][5].avg_score
							k_helper(te_lineup, te)
						else
							puts "TE SCORE INVALID"
						end
					end
					# k_helper(te_lineup, te)
				else
					puts "TE PRICE INVALID"
				end
				count += 1
			end
			te_lineup = nil
			te_helper_lineup = nil
		end

		def k_helper(k_helper_lineup, player)
			k_lineup = Lineup.new
			k_helper_lineup.roster.each do |ply|
				k_lineup.add_player(ply)
			end
			k_lineup.add_player(player)
			# if (k_lineup.price.to_i + @valid_checker['K']) <= 60000
			count = 0
			@all_players['K'].each do |k|

				break if count >= @k_limit
				if (k_lineup.price.to_i + k.price.to_i + @valid_checker['DEF']) <= 60000
					if @all_lineups['ol'].count < 6
						def_helper(k_lineup, k)
					else
						if (k_lineup.avg_score.to_i + k.avg_score.to_i + @valid_score['DEF']) > @all_lineups['ol'][5].avg_score
							def_helper(k_lineup, k)
						else
							puts "K SCORE INVALID"
						end
					end
					# def_helper(k_lineup, k)
				else
					puts "K PRICE INVALID"
				end
				count += 1
			end
			k_lineup = nil
			k_helper_lineup = nil
		end

		def def_helper(def_helper_lineup, player)
			def_lineup = Lineup.new
			def_helper_lineup.roster.each do |ply|
				def_lineup.add_player(ply)
			end
			def_lineup.add_player(player)
			# if (def_lineup.price.to_i + @valid_checker['DEF']) <= 60000
			count = 0
			@all_players['DEF'].each do |de|

				break if count >= @def_limit
				if (def_lineup.price.to_i + de.price.to_i) <= 60000
					final_helper(def_lineup, de)
				else
					puts "DEF INVALID"
				end
				count += 1
			end
			
			def_lineup = nil
			def_helper_lineup = nil
		end

		def final_helper(final_helper_lineup, player)
			final_lineup = Lineup.new
			final_helper_lineup.roster.each do |ply|
				final_lineup.add_player(ply)
			end
			final_lineup.add_player(player)
			ol_insert_check = true
			if @all_lineups['ol'].count < 6
				for i in 0...@all_lineups['ol'].count
					if final_lineup.avg_score > @all_lineups['ol'][i].avg_score
						@all_lineups['ol'].insert(i, final_lineup)
						ol_insert_check = false
						break
					end
				end
				if ol_insert_check
					@all_lineups['ol'] << final_lineup
					ol_insert_check = false
				end
			else
				if final_lineup.avg_score > @all_lineups['ol'][5].avg_score
					for i in 0...@all_lineups['ol'].count do
						if final_lineup.avg_score > @all_lineups['ol'][i].avg_score
							@all_lineups['ol'].insert(i, final_lineup)
							@all_lineups['ol'].pop
							insert_check = false
							break
						end
					end
				end
			end

			rl_insert_check = true
			if @all_lineups['rl'].count < 6
				for i in 0...@all_lineups['rl'].count
					if final_lineup.max_score > @all_lineups['rl'][i].max_score
						@all_lineups['rl'].insert(i, final_lineup)
						rl_insert_check = false
						break
					end
				end
				if rl_insert_check
					@all_lineups['rl'] << final_lineup
					rl_insert_check = false
				end
			else
				if final_lineup.max_score > @all_lineups['rl'][5].max_score
					for i in 0...@all_lineups['rl'].count do
						if final_lineup.max_score > @all_lineups['rl'][i].max_score
							@all_lineups['rl'].insert(i, final_lineup)
							@all_lineups['rl'].pop
							rl_insert_check = false
							break
						end
					end
				end
			end

			sl_insert_check = true
			if @all_lineups['sl'].count < 6
				for i in 0...@all_lineups['sl'].count
					if final_lineup.min_score > @all_lineups['sl'][i].min_score
						@all_lineups['sl'].insert(i, final_lineup)
						sl_insert_check = false
						break
					end
				end
				if sl_insert_check
					@all_lineups['sl'] << final_lineup
					sl_insert_check = false
				end
			else
				if final_lineup.min_score > @all_lineups['sl'][5].min_score
					for i in 0...@all_lineups['sl'].count do
						if final_lineup.min_score > @all_lineups['sl'][i].min_score
							@all_lineups['sl'].insert(i, final_lineup)
							@all_lineups['sl'].pop
							sl_insert_check = false
							break
						end
					end
				end
			end
			if ol_insert_check && rl_insert_check && sl_insert_check
				puts final_lineup.players_used
				final_lineup = nil
			end
			final_helper_lineup = nil
		end	
end