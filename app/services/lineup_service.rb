class LineupService
	def self.call
	  #binding.pry
      all_lineups = FfnService.call()
	end
end

class Lineup
	attr_accessor :roster, :min_score, :max_score, :avg_score, :best_score, :price, :lineup_count, :players_used

	def initialize
		@roster = Array.new
		@min_score = 0
		@max_score = 0
		@avg_score = 0
		@best_score = 0
		@price = 0
		@lineup_count = {
			'QB' => 1,
			'RB' => 2,
			'WR' => 3,
			'TE' => 1,
			'K' => 1,
			'DEF' => 1
		}
		@players_used = []
		self
	end

	def add_player(player)
		@roster << player
		@min_score += player.min_score
		@max_score += player.max_score
		@avg_score += player.avg_score
		@best_score += player.best_score
		@price += player.price
		@lineup_count[player.position] -= 1
		@players_used << player.name
		self
	end

	def get_scores
		obj = {
			'bl' => self.best_score,
			'ol' => self.avg_score,
			'rl' => self.max_score,
			'sl' => self.min_score
		}
		return obj
	end
end

class Position
	attr_accessor :position, :name, :min_score, :max_score, :avg_score, :best_score, :price, :exposure
	def initialize(ps, nm, mn, mx, av, pr)
		@position = ps
		@name = nm
		@min_score = mn.to_f
		@max_score = mx.to_f
		@avg_score = av.to_f
		@best_score = (mn.to_f + mx.to_f + av.to_f)/3
		@price = pr.to_i
		@exposure = 0
	end

	# def get_scores
	# 	obj = {
	# 		'bl' => self.best_score,
	# 		'ol' => self.avg_score,
	# 		'rl' => self.max_score,
	# 		'sl' => self.min_score
	# 	}
	# 	return obj
	# end
end