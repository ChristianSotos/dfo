require 'json'

class LineupsController < ApplicationController
  def index
    @lineups = LineupService.call(lineup_collection_params)
	@sl = Array.new()
	@rl = Array.new()
	@ol = Array.new()
	@sl << @lineups[0]
	@rl << @lineups[0]
	@ol << @lineups[0]
	for j in 0...@lineups.count
		push = true
		for i in 0...@sl.count do
			if @lineups[j].min_score >= @sl[i].min_score
				@sl.insert(i,@lineups[j])
				push = false
				break
			end
		end
		if push
			@sl << @lineups[j]
		else
			push = true
		end
		for i in 0...@rl.count do
			if @lineups[j].max_score >= @rl[i].max_score
				@rl.insert(i,@lineups[j])
				push = false
				break
			end
		end
		if push
			@rl << @lineups[j]
		else
			push = true
		end
		for i in 0...@ol.count do
			if @lineups[j].avg_score >= @ol[i].avg_score
				@ol.insert(i,@lineups[j])
				push = false
				break
			end
		end
		if push
			@ol << @lineups[j]
		else
			push = true
		end
	end
	# @safe_lineups = Array.new
	# @risk_lineups = Array.new
	# @opt_lineups = Array.new
	# for i in 0..5 do
	# 	@safe_lineups << sl[i]
	# 	@risk_lineups << rl[i]
	# 	@opt_lineups << ol[i]
	# end
  end

  private

  def lineup_collection_params
  	params.permit(:scoring, :week)
  end
end
