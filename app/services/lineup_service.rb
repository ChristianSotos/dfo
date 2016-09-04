class LineupService
	def self.call(params)
	  #binding.pry
      top_players = FfnService.call(params['scoring'], params['week'])
	end
end 