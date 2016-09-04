class LineupService
	def self.call(params)
	  #binding.pry
      all_lineups = FfnService.call(params['scoring'], params['week'])
      lineups = self.create_lineups(all_lineups)
	end
	def self.create_lineups(lineups)
		finished_lineups = Array.new
		for i in 0...lineups.count do
			new_l = Lineup.new
			lineup = lineups[i].to_a
			for j in 0...9 do
				player = lineup[j].to_h
				new_l.add_player(player['position'], player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player['price'])
			end 
			finished_lineups << new_l
		end
		finished_lineups
	end
end

class Lineup
	attr_accessor :roster, :min_score, :max_score, :avg_score, :price

	def initialize
		@roster = Array.new
		@min_score = 0
		@max_score = 0
		@avg_score = 0
		@price = 0
	end

	def add_player(ps, nm, mn, mx, av, pr)
		player = Position.new(ps, nm, mn, mx, av, pr)
		@roster << player
		@min_score += mn.to_f
		@max_score += mx.to_f
		@avg_score += av.to_f
		@price += pr.to_i
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