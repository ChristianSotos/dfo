class Test

	def self.call(players)
		new.call(players)
	end

	def call(players)
		@all_lineups = []
		@all_players = players

		@all_players['QB']['Rankings'].each do |player|
			lineup = Lineup.new
			player_db = Player.find_by(name: player['name'])
			if player_db
				lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
				players_used = {
					player['name'] => true
				}
				@all_players['RB']['Rankings'].each do |rb| do
					db_check = PLayer.find_by(name: rb['name'])
					if db_check
						rb1_helper(lineup, players_used, rb)
					end
				end
			end
		end
		return all_lineups
	end

	private

	attr_accessor :all_lineups, :all_players

		def rb2_helper(lineup, players_used, player)
			player_db = Player.find_by(name: player['name'])
			lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
			players_used[player['name']] = true
			@all_players['RB']['Rankings'].each do |rb2|
				if !players_used.has_key?(player['name'])
					db_check = Player.find_by(name: rb2['name'])
					if db_check
						wr1_helper(lineup, players_used, rb2)
					end
				end
			end
		end
		def wr1_helper(lineup, players_used, player)
			player_db = Player.find_by(name: player['name'])
			lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
			players_used[player['name']] = true
			@all_players['WR']['Rankings'].each do |wr1|
				if !players_used.has_key?(player['name'])
					db_check = Player.find_by(name: wr1['name'])
					if db_check
						wr2_helper(lineup, players_used, wr1)
					end
				end
			end
		end
		def wr2_helper(lineup, players_used, player)
			player_db = Player.find_by(name: player['name'])
			lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
			players_used[player['name']] = true
			@all_players['WR']['Rankings'].each do |wr2|
				if !players_used.has_key?(player['name'])
					db_check = Player.find_by(name: wr2['name'])
					if db_check
						wr3_helper(lineup, players_used, wr2)
					end
				end
			end
		end
		def wr3_helper(lineup, players_used, player)
			player_db = Player.find_by(name: player['name'])
			lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
			players_used[player['name']] = true
			@all_players['WR']['Rankings'].each do |wr3|
				if !players_used.has_key?(player['name'])
					db_check = Player.find_by(name: wr3['name'])
					if db_check
						te_helper(lineup, players_used, wr3)
					end
				end
			end
		end
		def te_helper(lineup, players_used, player)
			player_db = Player.find_by(name: player['name'])
			lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
			players_used[player['name']] = true
			@all_players['TE']['Rankings'].each do |te|
				db_check = Player.find_by(name: te['name'])
				if db_check
					k_helper(lineup, players_used, te)
				end
			end
		end
		def k_helper(lineup, players_used, player)
			player_db = Player.find_by(name: player['name'])
			lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
			players_used[player['name']] = true
			@all_players['K']['Rankings'].each do |k|
				db_check = Player.find_by(name: k['name'])
				if db_check
					def_helper(lineup, players_used, k)
				end
			end
		end
		def def_helper(lineup, players_used, player)
			player_db = Player.find_by(name: player['name'])
			lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
			players_used[player['name']] = true
			@all_players['DEF']['Rankings'].each do |de|
				db_check = Player.find_by(name: de['name'])
				if db_check
					final_helper(lineup, players_used, de)
				end
			end
		end
		def final_helper(lineup, players_used, player)
			player_db = Player.find_by(name: player['name'])
			lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
			@all_lineups << lineup
		end
		
end