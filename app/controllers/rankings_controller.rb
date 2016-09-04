class RankingsController < ApplicationController

	def index
	end

	def upload
		Player.import(params[:rankings])
		redirect_to :root
	end

end
