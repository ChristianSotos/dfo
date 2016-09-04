class OptimizeService

	def self.call(players)
		new.call(players)
	end

	def call(players)
		@all_lineups = []

		players['QB']['Rankings'].each do |player|
			lineup = Lineup.new
			player_db = Player.find_by(name: player['name'])
			if player_db
				lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
				lineup_count = {
					'QB' => 0,
					'RB' => 2,
					'WR' => 3,
					'TE' => 1,
					'K' => 1,
					'DEF' => 1
				}
				players_used = {
					player['name'] => true
				}
				helper(lineup, lineup_count, players_used, players)
			end
		end
		return all_lineups
	end

	private

	attr_accessor :all_lineups

		def helper(lineup, lineup_count, players_used, players)
			# if lineup.price > 75000
			# 	return false
			# end
			complete = true
			lineup_count.each do |pos|
				if pos[1] > 0
					complete = false
					break;
				end
			end
			if complete
				all_lineups << lineup
			end
			lineup_count.each do |pos|
				if pos[1] > 0
					players[pos[0]]['Rankings'].each do |player|
						if !players_used.has_key?(player['name'])
							player_db = Player.find_by(name: player['name'])
							if player_db
								lineup.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
								lineup_count[pos[0]] -= 1
							end
							players_used[player['name']] = true
							return helper(lineup, lineup_count, players_used, players)
						end
					end
				end
			end
		end
end