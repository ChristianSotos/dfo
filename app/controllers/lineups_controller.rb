require 'json'

class LineupsController < ApplicationController
  def index
    @lineups = LineupService.call()
	  @sl = @lineups['sl']
	  @rl = @lineups['rl']
	  @ol = @lineups['ol']
    @bl = @lineups['bl']
  end
end
