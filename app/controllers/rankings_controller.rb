class RankingsController < ApplicationController

	def index
	end

	def upload
		Player.delete_all
		Player.import(params[:rankings])
		redirect_to :root
	end

end
