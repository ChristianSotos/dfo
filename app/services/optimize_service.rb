class OptimizeService

	def self.call(players)
		new.call(players)
	end

	def call(players)
		@all_lineups = []

		players['QB']['Rankings'].each do |player|
			lineup = []
			player_db = Player.find_by(name: player['name'])
			if player_db
				player_cost = player_db.price
				lineup_sum = player_cost
				lineup_scores = {
					'min_score' => player['pprLow'].to_i,
					'max_score' => player['pprHigh'].to_i,
					'avg_score' => player['ppr'].to_i 
				}
				lineup_count = {
					'QB' => 0,
					'RB' => 2,
					'WR' => 3,
					'TE' => 1,
					'K' => 1,
					'DEF' => 1
				}
				player['price'] = player_cost
				lineup << player
				players_used = {
					player['name'] => true
				}
				helper(lineup, lineup_sum, lineup_scores, lineup_count, players_used, players)
			end
		end
		return all_lineups
	end

	private

	attr_accessor :all_lineups

		def helper(lineup, lineup_sum, lineup_scores, lineup_count, players_used, players)
			if lineup_sum > 70000
				return false
			end
			complete = true
			lineup_count.each do |pos|
				if pos[1] > 0
					complete = false
					break;
				end
			end
			if complete
				lineup << lineup_sum
				lineup << lineup_scores
				all_lineups << lineup
			end
			lineup_count.each do |pos|
				if pos[1] > 0
					players[pos[0]]['Rankings'].each do |player|
						if !players_used.has_key?(player['name'])
							player_db = Player.find_by(name: player['name'])
							if player_db
								player_cost = player_db.price
								lineup_sum += player_cost
								lineup_scores['min_score'] += player['pprLow'].to_i
								lineup_scores['max_score'] += player['pprHigh'].to_i
								lineup_scores['avg_score'] += player['ppr'].to_i
								lineup_count[pos[0]] -= 1
								player['price'] = player_cost
								lineup << player
							end
							players_used[player['name']] = true
							return helper(lineup, lineup_sum, lineup_scores, lineup_count, players_used, players)
						end
					end
				end
			end
		end
end