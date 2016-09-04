class Player < ActiveRecord::Base
	require 'csv'

	def self.import(file)
		CSV.foreach(file.path) do |row|
			Player.create(name: "#{row[2]} #{row[3]}", price: row[6]);
		end
	end
end
