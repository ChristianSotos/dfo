class LineupService
	def self.call(params)
	  #binding.pry
      top_players = FfnService.call(params['scoring'])
	end
end 