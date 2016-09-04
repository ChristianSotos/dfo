class FfnService
	BASE_PATH = "http://www.fantasyfootballnerd.com/service/weekly-rankings/json/az3uzjv2qfsd/QB/1"

	def self.call(scoring)
	  	uri = URI.parse([BASE_PATH, scoring].join('/'))
	  	http = Net::HTTP.new(uri.host, uri.port)
	  	#to be able to access https URL, these lines should be added
	  	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	  	request = Net::HTTP::Get.new(uri.request_uri)
	  	response = http.request(request)
	  	#store the body of the requested URI
	  	data = response.body
	  	#to parse JSON string, you may also use JSON.parse()
	  	#JSON.load() turns the data into a hash
	  	JSON.parse(data)
	end
end