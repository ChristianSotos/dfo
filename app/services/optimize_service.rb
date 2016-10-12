class OptimizeService

	def self.call(players)
		new.call(players)
	end

	def call(players)
		@all_lineups = []

		#limit how many players from each position to include in algorithm
		@rb_limit = 20
		@wr_limit = 40
		@qb_limit = 20
		@te_limit = 20
		@k_limit = 30
		@def_limit = 10

		#how many lineups to create
		@lineup_limit = 60

		#the percentage of lineups a player at each given position can be in (we call it exposure)
		qb_exposure = 0.4
		rb_exposure = 0.4
		wr_exposure = 0.4
		te_exposure = 0.4
		k_exposure = 0.5
		de_exposure = 0.5
		combo_exposure = 0.15

		#the object used throughout the algorithm for checking exposure
		@exposure_limit = {
			'QB' => (@lineup_limit.to_f * qb_exposure.to_f).to_i,
			'RB' => (@lineup_limit.to_f * rb_exposure.to_f).to_i,
			'WR' => (@lineup_limit.to_f * wr_exposure.to_f).to_i,
			'TE' => (@lineup_limit.to_f * te_exposure.to_f).to_i,
			'K' => (@lineup_limit.to_f * k_exposure.to_f).to_i,
			'DEF' => (@lineup_limit.to_f * de_exposure.to_f).to_i,
			'COMBO' => (@lineup_limit.to_f * combo_exposure.to_f).to_i
		}

		#object to hold the exposures of every player combination in use
		@exposure_combos = {}

		#create the players object
		@all_players = player_creator(players)
		#create the price and score validation objects
		@valid_price = valid_price_creator
		@valid_score = valid_score_creator
		#create the RB/WR combos
		@rw_combos = rw_combo_creator(rb_combo_creator, wr_combo_creator)
		@all_players['RB'] = nil
		@all_players['WR'] = nil
		#create the K/DEF combos
		@kd_combos = kd_combo_creator
		@all_players['K'] = nil
		@all_players['DEF'] = nil

		#begin lineup creation
		rw_helper

		return @all_lineups
	end

	private

	attr_accessor :all_lineups, :all_players, :rb_combos, :wr_combos, :valid_checker
		
		#create object of player instances
		def player_creator(players)
			def pc_helper(pos, players, pos_limit)
				pos_array = []
				players[pos]['Rankings'].each do |player|
					#if we find the player in the database(which means he's available in the draft pool) we add him to the array
					player_db = Player.find_by(name: player['name'])
					if player_db
						new_player = Position.new(pos, player['name'], player['pprLow'], player['pprHigh'], player['ppr'], player_db.price)
						pos_array << new_player
					end
					puts "PLAYER CREATOR"
				end

				#sort array by players best_score attributes
				pos_array.sort_by! do |ply|
					ply.best_score
				end

				return pos_array.reverse.take(pos_limit)
			end

			player_obj = {
				"QB" => pc_helper("QB", players, @qb_limit),
				"RB" => pc_helper("RB", players, @rb_limit),
				"WR" => pc_helper("WR", players, @wr_limit),
				"TE" => pc_helper("TE", players, @te_limit),
				"K" => pc_helper("K", players, @k_limit),
				"DEF" => pc_helper("DEF", players, @def_limit)
			}

			return player_obj
		end

		#create all player combinations
		def rb_combo_creator
			rb_combo_array = []
			for i in 0...@all_players['RB'].count do
				for j in (i+1)...@all_players['RB'].count do
					rb_combo_array << [@all_players['RB'][i], @all_players['RB'][j]]
					puts "RB COMBO CREATOR"
				end
			end

			rb_combo_array.sort_by! do |combo|
				combo[0].best_score + combo[1].best_score
			end

			return rb_combo_array.reverse
		end
		def wr_combo_creator
			wr_combo_array = []
			for i in 0...@all_players['WR'].count do
				for j in (i+1)...@all_players['WR'].count do
					for k in (j+1)...@all_players['WR'].count do
						wr_combo_array << [@all_players['WR'][i], @all_players['WR'][j], @all_players['WR'][k]]
						puts "WR COMBO CREATOR"
					end
				end
			end

			wr_combo_array.sort_by! do |combo|
				combo[0].best_score + combo[1].best_score + combo[2].best_score
			end

			return wr_combo_array.reverse
		end
		def rw_combo_creator(rb_combos, wr_combos)
			rw_combo_array = []
			for i in 0...rb_combos.count do
				for j in 0...wr_combos.count do
					if validator(nil, [rb_combos[i][0], rb_combos[i][1], wr_combos[j][0], wr_combos[j][1], wr_combos[j][2]], "QB")
						rw_combo_array << [rb_combos[i][0], rb_combos[i][1], wr_combos[j][0], wr_combos[j][1], wr_combos[j][2]]
					end
					puts "RW COMBO CREATOR"
				end
			end
			
			rw_combo_array.sort_by! do |combo|
				combo[0].best_score + combo[1].best_score + combo[2].best_score + combo[3].best_score + combo[4].best_score
			end

			return rw_combo_array.reverse
		end
		def kd_combo_creator
			kd_combo_array = []
			@all_players['K'].each do |k|
				@all_players['DEF'].each do |de|
					kd_combo_array << [k, de]
				end
			end

			kd_combo_array.sort_by! do |combo|
				combo[0].best_score + combo[1].best_score
			end

			return kd_combo_array.reverse
		end

		#create validation objects
		def valid_price_creator
			#finds the lowest possible price at each position
			def valid_helper(pos)
				pos_min = nil
				@all_players[pos].each do |player|
					if pos_min
						if player.price < pos_min
							pos_min = player.price
						end	
					else
						pos_min = player.price
					end
				end
				return pos_min
			end

			valid_price_obj = {
				"QB" => valid_helper("QB"),
				"TE" => valid_helper("TE"),
				 "K" => valid_helper("K"),
				 "DEF" => valid_helper("DEF")
			}

			#we add them to know the lowest possible price a lineup could moving forward from a given position
			valid_price_obj['K'] += valid_price_obj['DEF']
			valid_price_obj["TE"] += valid_price_obj['K']
			valid_price_obj['QB'] += valid_price_obj['TE']

			return valid_price_obj
		end

		def valid_score_creator
			#highest scoring player at each position
			valid_score_obj = {
				"QB" => @all_players['QB'][0].best_score,
				"TE" => @all_players['TE'][0].best_score,
				"K" => @all_players['K'][0].best_score,
				"DEF" => @all_players['DEF'][0].best_score
			}
			#we add them to know the highest possible score a lineup can acheive moving forward from a given position
			valid_score_obj['K'] += valid_score_obj['DEF']
			valid_score_obj['TE'] += valid_score_obj['K']
			valid_score_obj['QB'] += valid_score_obj['TE']

			return valid_score_obj
		end

		#method to check lineups against validation objects
		def validator(lineup_array, player_array, val_pos = nil)
			#will hold lowest possible price moving forward
			valid_price = 0
			#will hod highest possible score moving forward
			valid_score = 0
			#will be a flag for checking player exposure
			valid_exposure = true

			#iterate through each player in lineup
			if lineup_array
				lineup_array.each do |ply|
					#check to see if player's exposure is too high
					if ply.exposure >= @exposure_limit[ply.position]
						valid_exposure = false
					end
					#add players to score and price to local variables
					valid_price += ply.price.to_i
					valid_score += ply.best_score.to_i
				end
			end

			#iterate through possible additions to the lineup
			if player_array
				player_array.each do |ply|
					#check to see if player's exposure is too high
					if ply.exposure >= @exposure_limit[ply.position]
						valid_exposure = false
					end
					#add players to score and price to local variables
					valid_price += ply.price.to_i
					valid_score += ply.best_score.to_i
				end
			end
			
			#if passed a position to use for validation object add the coresponding price & score to local variables
			if val_pos
				valid_price += @valid_price[val_pos].to_i
				valid_score += @valid_score[val_pos].to_i
			end

			if valid_price > 60000
				return false
			end

			#we only want to check the lineup count if the lineup has no players with max exposure
			if valid_exposure
				if @all_lineups.count < @lineup_limit
					return true
				end
			end

			#only allow the lineup to proceed if it's highest possible score moving forward will be high enough to include in the final array
			if valid_score > @all_lineups.last.best_score
				return true
			end

			#if the final array is full and the valid_score is too low we will return false
			return false
		end

		#method to update player and combo exposures when a lineup is inserted into or removed from final array
		def exposure_update(new_lineup, old_lineup=nil)
			#if passed a lineup to be removed we have to decrement exposures
			if old_lineup
				old_lineup.roster.each do |ply|
					ply.exposure -= 1
				end
				for i in 0...old_lineup.roster.count do
					for j in (i+1)...old_lineup.roster.count do
						#creates exposure_combo hash key
						combo_str = old_lineup.roster[i].name + "-" + old_lineup.roster[j].name
						@exposure_combos[combo_str] -= 1
					end
				end
			end

			#if passed a lineup to be inserted we have to increment or instantiate exposures
			if new_lineup
				new_lineup.roster.each do |ply|
					ply.exposure += 1
				end
				for i in 0...new_lineup.roster.count do
					for j in (i+1)...new_lineup.roster.count do
						#creates exposure_combo hash key
						combo_str = new_lineup.roster[i].name + "-" + new_lineup.roster[j].name
						if @exposure_combos[combo_str]
							@exposure_combos[combo_str] += 1
						else
							@exposure_combos[combo_str] = 1
						end
					end
				end
			end
		end

		#BEGIN LINEUP CREATIONS
		def rw_helper
			for i in 0...@rw_combos.count do
				loading = ((i.to_f / @rw_combos.count.to_f)*100).round(2)
				puts i.to_s + "/" + @rw_combos.count.to_s + "--" + loading.to_s + "%"

				#check lineup against validator
				if validator(@rw_combos[i], [], 'QB')
					#pass lineup along to qb additions
					qb_helper(@rw_combos[i])
				end
			end
		end

		def qb_helper(qb_helper_lineup)
			#creates a new array
			qb_lineup = [].concat(qb_helper_lineup)

			count = 0
			@all_players['QB'].each do |qb|
				#check lineup and possible qb against validator
				if validator(qb_lineup, [qb], 'TE')
					#insert_check will tell us whether or not the lineup that is passed along was eventually made into a lineup that was inserted in the final array
					insert_check = te_helper(qb_lineup, qb)
					if insert_check
						count += 1
					end

					#we return if we have succesfully added 2 QB's to the lineup
					#we do this to limit lineup repition and increase variance and coverage
					return true if count >= 2
				end
			end
			qb_lineup = nil
			qb_helper_lineup = nil
		end
		def te_helper(te_helper_lineup, player)
			te_lineup = [player].concat(te_helper_lineup)
			count = 0
			@all_players['TE'].each do |te|
				if validator(te_lineup, [te])
					insert_check = kd_helper(te_lineup, te)
					if insert_check
						count += 1
					end
					return true if count >= 2
				end
			end
			te_lineup = nil
			te_helper_lineup = nil
			return false
		end

		def kd_helper(kd_helper_lineup, player)
			kd_lineup = [].concat(kd_helper_lineup).concat([player])

			@kd_combos.each do |combo|
				if validator(kd_lineup, [combo[0], combo[1]])
					#we only allow the highest possible K/DEF combo to be attached to lineup to limit repetition
					return final_helper(kd_lineup, combo[0], combo[1])
				end
			end
			kd_helper_lineup = nil
			kd_lineup = nil
			return false
		end

		def final_helper(final_helper_lineup, player1, player2)
			#flag for checking exposure
			valid_exposure = true
			#will hold players and combos that exceed exposure limits
			exposure_players = []
			exposure_combos = []
			
			#create Lineup class instance
			final_lineup = Lineup.new
			final_helper_lineup.each do |ply|
				if ply.exposure >= @exposure_limit[ply.position]
					valid_exposure = false
					exposure_players << ply
				end
				final_lineup.add_player(ply)
			end

			#check lineup roster combinations and against exposure limits
			for i in 0...final_lineup.roster.count do
				for j in (i+1)...final_lineup.roster.count do
					#creates exposure_combo hash key
					combo_str = final_lineup.roster[i].name + "-" + final_lineup.roster[j].name
					if @exposure_combos[combo_str]
						if @exposure_combos[combo_str] > @exposure_limit['COMBO']
							valid_exposure = false
							exposure_combos << [final_lineup.roster[i], final_lineup.roster[j]]
						end
					end
				end
			end

			#add K & DEF to lineup
			final_lineup.add_player(player1)
			final_lineup.add_player(player2)

			#if all players & combos meet exposure standards we pass the lineup to lineup_insertion mehtod
			if valid_exposure
				insert_check = lineup_insertion(final_lineup)

				if insert_check
					return true
				else
					final_lineup = nil
					return false
				end
			else
				#send lineup and exposure players/combos to exposure_helper method
				return exposure_helper(final_lineup, exposure_players, exposure_combos)
			end

		end

		def lineup_insertion(insert_lineup)
			insert_check = true

			#check to make sure lineup isnt already in array
			if !@all_lineups.include?(insert_lineup)
				for i in 0...@all_lineups.count do
					#iterate through lineups until we find a lineup lower than new lineup
					if insert_lineup.best_score > @all_lineups[i].best_score
						#insert lineup into array
						@all_lineups.insert(i, insert_lineup)
						#if array exceeds lineup_limit, pop off the last element
						if @all_lineups.count > @lineup_limit
							exposure_update(insert_lineup, @all_lineups.last)
							@all_lineups.pop
						else
							exposure_update(insert_lineup)
						end
						puts insert_lineup.players_used
						insert_check = false
						break
					end
				end
			end

			#if we get through the whole array without inserting the lineup AND there is still room in the final array, we add it onto the end
			if @all_lineups.count < @lineup_limit && insert_check && !@all_lineups.include?(insert_lineup)
				exposure_update(insert_lineup)
				@all_lineups << insert_lineup
				puts insert_lineup.players_used
				insert_check = false
			end

			if insert_check 
				return false
			else 
				return true
			end
		end

		def exposure_helper(insert_lineup, players, combos)
			insert_check = false

			#create object of all the players with exceeded exposure set to false
			player_check_obj = {}
			players.each do |ply|
				player_check_obj[ply.name] = false
			end
			#create object of all the combos with exceeded exposure set to false
			combo_check_obj = {}
			combos.each do |combo|
				combo_str = combo[0].name + "-" + combo[1].name
				combo_check_obj[combo_str] = false
			end

			if !@all_lineups.include?(insert_lineup)
				#we start from the back of the array
				i = @all_lineups.count - 1
				while i >= 0
					#checking if the lineup contains all players and combos that exceed exposure in new lineup
					all_player_check = true
					players.each do |ply|
						if @all_lineups[i].roster.include?(ply)
							#if the lineup does contain the player and we haven't already found a lineup with this player, we will set the object property to the index of the lineup
							if !player_check_obj[ply.name]
								player_check_obj[ply.name] = i.to_i
							end
						else
							all_player_check = false
						end
					end
					all_combo_check = true
					combos.each do |combo|
						if @all_lineups[i].roster.include?(combo[0]) && @all_lineups[i].roster.include?(combo[1])
							combo_str = combo[0].name + "-" + combo[1].name
							#if the lineup does contain the combo of players and we haven't already found a lineup with this combo, we will set the object property to the index of the lineup
							if !combo_check_obj[combo_str]
								combo_check_obj[combo_str] = i
							end
						else
							all_combo_check = false
						end
					end

					#if the lineup contains all players AND combos that exceed exposure in the new lineup, we will compare the two
					if all_player_check && all_combo_check
						#if the new lineups score is greater than this lineups score we will swap them out and resort the array
						if insert_lineup.best_score > @all_lineups[i].best_score
							exposure_update(insert_lineup, @all_lineups[i])
							@all_lineups[i] = insert_lineup
							puts insert_lineup.players_used
							insert_check = true
							j = i
							while j > 0
								if @all_lineups[j].best_score > @all_lineups[j-1].best_score
									temp = @all_lineups[j]
									@all_lineups[j] = @all_lineups[j-1]
									@all_lineups[j-1] = temp
								else
									j = 0
								end
								j -= 1
							end
						end
						return insert_check
					else
						#we check to see if we have found a lineup for every player that exceeds exposure
						player_check_flag = true
						player_check_obj.each do |ply, status|
							if status == false
								player_check_flag = false
								break
							end
						end
						#we check to see if we have found a lineup for every combo that exceeds exposure
						combo_check_flag = true
						combo_check_obj.each do |combo, status|
							if status == false
								combo_check_flag = false
								break
							end
						end

						#if we have found lineups for every exposure exceeding player and combo, we will compare these lineups against the new lineup
						if player_check_flag && combo_check_flag
							#we create an array of the indexes of the lineups
							lineup_positions = []
							player_check_obj.each do |ply, ind|
								if !lineup_positions.include?(ind)
									lineup_positions << ind
								end
							end
							combo_check_obj.each do |combo, ind|
								if !lineup_positions.include?(ind)
									lineup_positions << ind
								end
							end
							lineup_positions.sort!.reverse!
							#get average score of the lineups
							total_score = 0
							lineup_positions.each do |ind|
								total_score += @all_lineups[ind].best_score.to_f
							end
							avg_score = total_score.to_f / lineup_positions.count.to_f

							#compare average score of lineups to score of new lineup
							if insert_lineup.best_score > avg_score
								#if new lineups is greater we will remove all of the lineups in order satisfy exposure standards before inserting new lineup
								lineup_positions.each do |ind|
									exposure_update(nil, @all_lineups[ind])
									@all_lineups.delete_at(ind)
								end
								#send lineup to lineup_insertion for proper insertion
								return lineup_insertion(insert_lineup)
							end
						end
					end

					i -= 1
				end
			end

			return false
		end
end