class FfnService
	BASE_PATH = "http://www.fantasyfootballnerd.com/service/weekly-rankings/json/az3uzjv2qfsd"
	$positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF']

	def self.call()
		players = {}
		week = 1
		scoring = 1
		for i in 0..6 do
		  	uri = URI.parse([BASE_PATH, $positions[i], week, scoring].join('/'))
		  	http = Net::HTTP.new(uri.host, uri.port)
		  	#to be able to access https URL, these lines should be added
		  	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		  	request = Net::HTTP::Get.new(uri.request_uri)
		  	response = http.request(request)
		  	#store the body of the requested URI
		  	data = response.body
		  	#to parse JSON string, you may also use JSON.parse()
		  	#JSON.load() turns the data into a hash
		  	players[$positions[i]] = JSON.parse(data)
		end
		all_lineups = OptimizeService.call(players)
	end
end