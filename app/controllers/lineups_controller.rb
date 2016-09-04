require 'json'

class LineupsController < ApplicationController
  def index
    @lineups = LineupService.call(lineup_collection_params)
  end

  private

  def lineup_collection_params
  	params.permit(:scoring, :week)
  end
end
