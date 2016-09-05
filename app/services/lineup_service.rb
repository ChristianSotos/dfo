class LineupService
	def self.call(params)
	  #binding.pry
      all_lineups = FfnService.call(params['scoring'], params['week'])
	end
end

class Lineup
	attr_accessor :roster, :min_score, :max_score, :avg_score, :price, :lineup_count, :players_used

	def initialize
		@roster = Array.new
		@min_score = 0
		@max_score = 0
		@avg_score = 0
		@price = 0
		@lineup_count = {
			'QB' => 1,
			'RB' => 2,
			'WR' => 3,
			'TE' => 1,
			'K' => 1,
			'DEF' => 1
		}
		@players_used = {}
		self
	end

	def add_player(ps, nm, mn, mx, av, pr)
		player = Position.new(ps, nm, mn, mx, av, pr)
		@roster << player
		@min_score += mn.to_f
		@max_score += mx.to_f
		@avg_score += av.to_f
		@price += pr.to_i
		@lineup_count[ps] -= 1
		@players_used[nm] = true
		self
	end
end

class Position
	attr_accessor :position, :name, :min_score, :max_score, :avg_score, :price
	def initialize(ps, nm, mn, mx, av, pr)
		@position = ps
		@name = nm
		@min_score = mn.to_f
		@max_score = mx.to_f
		@avg_score = av.to_f
		@price = pr.to_i
	end
end