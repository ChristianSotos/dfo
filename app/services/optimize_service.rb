class OptimizeService

	def self.call(players)
		new.call(players)
	end

	def call(players)
		@all_lineups = []
		@all_players = player_creator(players)
		@valid_checker = valid_creator
		@rb_combos = rb_combo_creator
		@wr_combos = wr_combo_creator
		@rw_combos = rw_combo_creator
		#@valid_score = valid_score_helper
		#@min_score = 0

		rw_helper

		puts @all_lineups.count
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
			
			puts rb_array

			for i in 0...13 do
				for j in (i+1)...13 do
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
			for i in 0...13 do
				for j in (i+1)...13 do
					for k in (j+1)...13 do
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
					puts rw_combo_array.count
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

		# def valid_score_helper
		# 	valid_score_obj = { 
		# 		"RB" => (@rb_combos[0][0].avg_score + @rb_combos[0][1].avg_score),
		# 		"WR" => (@wr_combos[0][0].avg_score + @wr_combos[0][1].avg_score + @wr_combos[0][2].avg_score),
		# 		"TE" => @all_players['TE'][0].avg_score,
		# 		"K" => @all_players['K'][0].avg_score,
		# 		"DEF" => @all_players['DEF'][0].avg_score
		# 	}
		# 	valid_score_obj['K'] += valid_score_obj['DEF']
		# 	valid_score_obj['TE'] += valid_score_obj['K']
		# 	valid_score_obj['WR'] += valid_score_obj['TE']
		# 	valid_score_obj['RB'] += valid_score_obj['WR']

		# 	puts valid_score_obj
		# 	return valid_score_obj
		# end

		#BEGIN LINEUP CREATIONS
		def rw_helper
			for i in 0...@rw_combos.count do
				rw_lineup = Lineup.new
				for j in 0...@rw_combos[i].count do
					rw_lineup.add_player(@rw_combos[i][j])
				end
				if ((rw_lineup.price.to_i + valid_checker['QB']) <= 60000)
					qb_helper(rw_lineup)
				end
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
				break if count >= 13
				if (qb_lineup.price.to_i + qb.price.to_i + @valid_checker['TE']) <= 60000
					te_helper(qb_lineup, qb)
				else
					puts "QB INVALID"
				end
				count += 1
			end
		end

		# def rb_helper(player)
		# 	for i in 0...@rb_combos.count
		# 		rb_lineup = Lineup.new
		# 		rb_lineup.add_player(player)
		# 		rb_lineup.add_player(@rb_combos[i][0])
		# 		rb_lineup.add_player(@rb_combos[i][1])
		# 		if ((rb_lineup.price.to_i + @valid_checker['WR']) <= 60000)
		# 			wr_helper(rb_lineup)
		# 		else
		# 			#puts "RB INVALID"
		# 		end
		# 	end
		# end
		# def wr_helper(wr_helper_lineup)
		# 	for i in 0...@wr_combos.count
		# 		wr_lineup = Lineup.new
		# 		wr_helper_lineup.roster.each do |ply|
		# 			wr_lineup.add_player(ply)
		# 		end
		# 		for j in 0...@wr_combos[i].count
		# 			wr_lineup.add_player(@wr_combos[i][j])
		# 		end
		# 		if ((wr_lineup.price.to_i + @valid_checker['TE']) <= 60000)
		# 			te_helper(wr_lineup)
		# 		else
		# 			#puts "WR INVALID"
		# 		end
		# 	end

		# end

		def te_helper(te_helper_lineup, player)
			te_lineup = Lineup.new
			te_helper_lineup.roster.each do |ply|
				te_lineup.add_player(ply)
			end
			te_lineup.add_player(player)
			# if (te_lineup.price.to_i + @valid_checker['TE']) <= 60000
			count = 0
			@all_players['TE'].each do |te|
				break if count >= 13
				if (te_lineup.price.to_i + te.price.to_i + @valid_checker['K']) <= 60000
					k_helper(te_lineup, te)
				else
					puts "TE INVALID"
				end
				count += 1
			end
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
				break if count >= 13
				if (k_lineup.price.to_i + k.price.to_i + @valid_checker['DEF']) <= 60000
					def_helper(k_lineup, k)
				else
					puts "K INVALID"
				end
				count += 1
			end
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
				break if count >= 13
				if (def_lineup.price.to_i + de.price.to_i) <= 60000
					final_helper(def_lineup, de)
				else
					puts "DEF INVALID"
				end
				count += 1
			end
		end
		def final_helper(final_helper_lineup, player)
			final_lineup = Lineup.new
			final_helper_lineup.roster.each do |ply|
				final_lineup.add_player(ply)
			end
			final_lineup.add_player(player)
			#if final_lineup.price.to_i <= 60000
				#puts final_lineup.players_used
			@all_lineups << final_lineup
			puts @all_lineups.count
			#else
				#puts "INVALID"
			#end
		end	
end