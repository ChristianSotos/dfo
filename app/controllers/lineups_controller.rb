require 'json'

class LineupsController < ApplicationController
  def index
    @lineups = LineupService.call()

    # lineup_count = (@lineups['ol'].count.to_f * 4.to_f).to_f
    lineup_count = @lineups.count.to_f

    iexp = {
    	'QB' => {},
    	'RB' => {},
    	'WR' => {},
    	'TE' => {},
    	'K' => {},
    	'DEF' => {}
    }

    # @scores = {
    # 	'Best Lineups' => {
    # 		'avg' => 0.0,
    # 		'total' => 0.0
    # 		},
    # 	'Optimal Lineups' => {
    # 		'avg' => 0.0,
    # 		'total' => 0.0
    # 		}, 
    # 	'Risk Lineups' => {
    # 		'avg' => 0.0,
    # 		'total' => 0.0
    # 		},
    # 	'Safe Lineups' => {
    # 		'avg' => 0.0,
    # 		'total' => 0.0
    # 		},
    # 	'All Lineups' => {
    # 		'avg' => 0.0,
    # 		'total' => 0.0
    # 	}
    # }

    @scores = {
        'avg' => 0.0,
        'total' => 0.0
    }

    # @lineups['sl'].each do |ln|
    # 	@scores['Safe Lineups']['total'] += ln.min_score.to_f
    # 	ln.roster.each do |ply|
    # 		if !iexp[ply.position][ply.name]
    # 			iexp[ply.position][ply.name] = ply.exposure
    # 		end
    # 	end
    # end
    # @scores['Safe Lineups']['avg'] = (@scores['Safe Lineups']['total'].to_f / @lineups['sl'].count.to_f).to_f

    # @lineups['rl'].each do |ln|
    # 	@scores['Risk Lineups']['total'] += ln.max_score.to_f
    # 	ln.roster.each do |ply|
    # 		if !iexp[ply.position][ply.name]
    # 			iexp[ply.position][ply.name] = ply.exposure
    # 		end
    # 	end
    # end
    # @scores['Risk Lineups']['avg'] = (@scores['Risk Lineups']['total'].to_f / @lineups['rl'].count.to_f).to_f

    # @lineups['ol'].each do |ln|
    # 	@scores['Optimal Lineups']['total'] += ln.avg_score.to_f
    # 	ln.roster.each do |ply|
    # 		if !iexp[ply.position][ply.name]
    # 			iexp[ply.position][ply.name] = ply.exposure
    # 		end
    # 	end
    # end
    # @scores['Optimal Lineups']['avg'] = (@scores['Optimal Lineups']['total'].to_f / @lineups['ol'].count.to_f).to_f

    # @lineups['bl'].each do |ln|
    # 	@scores['Best Lineups']['total'] += ln.best_score.to_f
    # 	ln.roster.each do |ply|
    # 		if !iexp[ply.position][ply.name]
    # 			iexp[ply.position][ply.name] = ply.exposure
    # 		end
    # 	end
    # end
    # @scores['Best Lineups']['avg'] = (@scores['Best Lineups']['total'].to_f / @lineups['bl'].count.to_f).to_f

    # @scores['All Lineups']['total'] = @scores['Safe Lineups']['total'] + @scores['Optimal Lineups']['total'] + @scores['Risk Lineups']['total'] + @scores['Best Lineups']['total']
    # @scores['All Lineups']['avg'] = (@scores['All Lineups']['total'].to_f / (@lineups['bl'].count.to_f*4)).to_f

    @lineups.each do |ln|
        @scores['total'] += ln.best_score.to_f
        ln.roster.each do |ply|
            if !iexp[ply.position][ply.name]
                iexp[ply.position][ply.name] = ply.exposure
            end
        end
    end
    @scores['avg'] = (@scores['total'].to_f / lineup_count.to_f).to_f

    @exposure = {
    	'QB' => [],
    	'RB' => [],
    	'WR' => [],
    	'TE' => [],
    	'K' => [],
    	'DEF' => []
    }

    iexp.each do |pos, pos_obj|
    	pos_obj.each do |ply_name, count|
    		player_obj ={
    			'name' => ply_name,
    			'perc' => ((count.to_f / lineup_count.to_f) * 100.to_f)
    		}
    		insert_check = true
    		for i in 0...@exposure[pos].count do
    			if player_obj['perc'] > @exposure[pos][i]['perc']
    				@exposure[pos].insert(i,player_obj)
    				insert_check = false
    				break
    			end
    		end
    		if insert_check
    			@exposure[pos] << player_obj
    		end
    	end
    end

	# @sl = @lineups['sl']
	# @rl = @lineups['rl']
	# @ol = @lineups['ol']
 #    @bl = @lineups['bl']
  end
end
