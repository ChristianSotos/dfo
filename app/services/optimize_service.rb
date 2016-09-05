class OptimizeService

	def self.call(players)
		new.call(players)
	end

	def call(players)
		@all_lineups = []
		@all_players = players
		@rb_combos = []
		@wr_combos = []
		@valid_checker = {
			"RB" => nil,
			"WR" => nil,
			"TE" => nil,
			"K" => nil,
			"DEF" => nil
		}
		rb_combo_creator
		wr_combo_creator
		valid_creator

		count = 0
		@all_players['QB']['Rankings'].each do |player|
			break if count >= 10
			player_db = Player.find_by(name: player['name'])
			if player_db
				if (player_db.price + @valid_checker['RB']) <= 60000
					rb_helper(player)
				end
			end
			count += 1
		end
		puts @all_lineups.count
		return @all_lineups
	end

	private

	attr_accessor :all_lineups, :all_players, :rb_combos, :wr_combos, :valid_checker
		def rb_combo_creator
			rb_array = []
			@all_players['RB']['Rankings'].each do |player|
				rb_array << player
			end
			for i in 0...10 do
				for j in (i+1)...10 do
					@rb_combos << [rb_array[i], rb_array[j]]
				end
			end
		end
		def wr_combo_creator
			wr_array = []
			@all_players['WR']['Rankings'].each do |player|
				wr_array << player
			end
			for i in 0...10 do
				for j in (i+1)...10 do
					for k in (j+1)...10 do
						@wr_combos << [wr_array[i], wr_array[j], wr_array[k]]
					end
				end
			end
		end
		def valid_creator
			@all_players['DEF']['Rankings'].each do |player|
				player_db = Player.find_by(name: player['name'])
				if @valid_checker['DEF']
					if player_db
						if player_db.price < @valid_checker['DEF']
							@valid_checker['DEF'] = player_db.price
						end	
					end
				else
					if player_db
						@valid_checker['DEF'] = player_db.price
					end
				end
			end
			@all_players['K']['Rankings'].each do |player|
				player_db = Player.find_by(name: player['name'])
				if @valid_checker['K']
					if player_db
						if player_db.price < @valid_checker['K']
							@valid_checker['K'] = player_db.price
						end
					end
				else
					if player_db
						@valid_checker['K'] = player_db.price
					end
				end
			end
			@all_players['TE']['Rankings'].each do |player|
				player_db = Player.find_by(name: player['name'])
				if @valid_checker['TE']
					if player_db
						if player_db.price < @valid_checker['TE']
							@valid_checker['TE'] = player_db.price
						end
					end
				else
					if player_db
						@valid_checker['TE'] = player_db.price
					end
				end
			end
			for i in 0...@wr_combos.count do
				wr_sum = 0
				for j in 0...@wr_combos[i].count do
					player_db = Player.find_by(name: @wr_combos[i][j]['name'])
					if player_db
						wr_sum += player_db.price
					end
				end
				if @valid_checker['WR']
					if wr_sum < @valid_checker['WR']
						@valid_checker['WR'] = wr_sum
					end
				else
					@valid_checker['WR'] = wr_sum
				end
			end
			for i in 0...@rb_combos.count do
				rb_sum = 0
				for j in 0...@rb_combos[i].count do
					player_db = Player.find_by(name: @rb_combos[i][j]['name'])
					if player_db
						rb_sum += player_db.price
					end
				end
				if @valid_checker['RB']
					if rb_sum < @valid_checker['RB']
						@valid_checker['RB'] = rb_sum
					end
				else
					@valid_checker['RB'] = rb_sum
				end
			end	
			valid_checker['K'] += valid_checker['DEF']
			valid_checker['TE'] += valid_checker['K']
			valid_checker['WR'] += valid_checker['TE']
			valid_checker['RB'] += valid_checker['WR']
		end

		def rb_helper(player)
			for i in 0...@rb_combos.count
				rb_lineup = Lineup.new
				player_db = Player.find_by(name: player['name'])
				rb_lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
				player_db = Player.find_by(name: @rb_combos[i][0]['name'])
				rb_lineup.add_player(@rb_combos[i][0]['position'], @rb_combos[i][0]['name'], @rb_combos[i][0]['pprLow'], @rb_combos[i][0]['pprHigh'], @rb_combos[i][0]['ppr'], player_db.price)
				player_db = Player.find_by(name: @rb_combos[i][1]['name'])
				rb_lineup.add_player(@rb_combos[i][1]['position'], @rb_combos[i][1]['name'], @rb_combos[i][1]['pprLow'], @rb_combos[i][1]['pprHigh'], @rb_combos[i][1]['ppr'], player_db.price)
				if (rb_lineup.price.to_i + @valid_checker['WR']) <= 60000
					wr_helper(rb_lineup)
				end
			end
		end
		def wr_helper(wr_helper_lineup)
			for i in 0...@wr_combos.count
				wr_lineup = Lineup.new
				wr_helper_lineup.roster.each do |ply|
					wr_lineup.add_player(ply.position, ply.name, ply.min_score, ply.max_score, ply.avg_score, ply.price)
				end
				for j in 0...@wr_combos[i].count
					player_db = Player.find_by(name: @wr_combos[i][j]['name'])
					wr_lineup.add_player(@wr_combos[i][j]['position'], @wr_combos[i][j]['name'], @wr_combos[i][j]['pprLow'], @wr_combos[i][j]['pprHigh'], @wr_combos[i][j]['ppr'], player_db.price)
				end
				if (wr_lineup.price.to_i + @valid_checker['TE']) <= 60000
					te_helper(wr_lineup)
				end
			end

		end

		def te_helper(te_helper_lineup)
			te_lineup = Lineup.new
			te_helper_lineup.roster.each do |ply|
				te_lineup.add_player(ply.position, ply.name, ply.min_score, ply.max_score, ply.avg_score, ply.price)
			end
			if te_lineup.price.to_i <= 60000
				count = 0
				@all_players['TE']['Rankings'].each do |te|
						break if count >= 10
						if (te_lineup.price.to_i + @valid_checker['K']) <= 60000
							k_helper(te_lineup, te)
						end
						count += 1
				end
			end
		end
		def k_helper(k_helper_lineup, player)
			k_lineup = Lineup.new
			k_helper_lineup.roster.each do |ply|
				k_lineup.add_player(ply.position, ply.name, ply.min_score, ply.max_score, ply.avg_score, ply.price)
			end
			if k_lineup.price.to_i <= 60000
				player_db = Player.find_by(name: player['name'])
				if player_db
					k_lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
					count = 0
					@all_players['K']['Rankings'].each do |k|
						break if count >= 10
						if (k_lineup.price.to_i + @valid_checker['DEF']) <= 60000
							def_helper(k_lineup, k)
						end
						count += 1
					end
				end
			end
		end
		def def_helper(def_helper_lineup, player)
			def_lineup = Lineup.new
			def_helper_lineup.roster.each do |ply|
				def_lineup.add_player(ply.position, ply.name, ply.min_score, ply.max_score, ply.avg_score, ply.price)
			end
			if def_lineup.price.to_i <= 60000
				player_db = Player.find_by(name: player['name'])
				if player_db
					def_lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
					count = 0
					@all_players['DEF']['Rankings'].each do |de|
						break if count >= 10
						final_helper(def_lineup, de)
						count += 1
					end
				end
			end
		end
		def final_helper(final_helper_lineup, player)
			final_lineup = Lineup.new
			final_helper_lineup.roster.each do |ply|
				final_lineup.add_player(ply.position, ply.name, ply.min_score, ply.max_score, ply.avg_score, ply.price)
			end
			player_db = Player.find_by(name: player['name'])
			if player_db
				final_lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
				if final_lineup.price.to_i <= 60000
					puts final_lineup.players_used
					@all_lineups << final_lineup
				end
			end
		end	
end

# class OptimizeService

# 	def self.call(players)
# 		new.call(players)
# 	end

# 	def call(players)
# 		@all_lineups = []

# 		players['QB']['Rankings'].each do |player|
# 			lineup = Lineup.new
# 			player_db = Player.find_by(name: player['name'])
# 			if player_db
# 				lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
# 				players_used = {
# 					player['name'] => true
# 				}
# 				helper(lineup, players_used, players)
# 				players['RB']['Rankings'].each do |rb|
# 					rb_db = Player.find_by(name: rb['name'])
# 					if rb_db
# 						rb1 = Lineup.new
# 						rb1.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
# 						rb1.add_player(rb['position'], rb['name'], rb['pprLow'], rb['pprHigh'], rb['ppr'], rb_db.price)
# 						rb1_pu = players_used
# 						rb1_pu[rb['name']] = true
# 						helper(rb1, rb1_pu, players)
# 					end
# 				end
# 			end
# 		end
# 		return all_lineups
# 	end

# 	private

# 	attr_accessor :all_lineups

# 		def helper(lineup, players_used, players)
# 			# if lineup.price > 75000
# 			# 	return false
# 			# end
# 			complete = true
# 			lineup.lineup_count.each do |pos|
# 				if pos[1] > 0
# 					complete = false
# 					break;
# 				end
# 			end
# 			if complete
# 				all_lineups << lineup
# 				return
# 			end
# 			lineup.lineup_count.each do |pos|
# 				if pos[1] > 0 
# 					players[pos[0]]['Rankings'].each do |player|
# 						if !players_used.has_key?(player['name']) && lineup.lineup_count[pos[0]] > 0
# 							player_db = Player.find_by(name: player['name'])
# 							players_used[player['name']] = true
# 							if player_db
# 								lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
# 							end
# 							return helper(lineup, players_used, players)
# 						end
# 					end
# 				end
# 			end
# 		end
# 		def caller(lineup, players_used, players)
# 			return helper(lineup, players_used, players)
# 		end
# end