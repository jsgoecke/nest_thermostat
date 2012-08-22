class NestThermostat
	
	attr_reader :credentials, :user_id, :serial
	
	
	##
	# Create a NestThermostat object
	#
	# @return [Object] an instantiated NestThermostat object
	def initialize(options={})
		raise ArgumentError, 'Must provide a Hash' if !options.instance_of?(Hash)
		raise ArgumentError, 'Must provide a :username' if !options[:username]
		raise ArgumentError, 'Must provide a :password' if !options[:password]
		
		@options = { :index      => 0,
								 :units      => 'F',
								 :base_url   => 'https://home.nest.com',
								 :user_agent => 'Nest/1.1.0.10 CFNetwork/548.0.4'	}.merge!(options)

		@serial = @options['serial']
		@userid = @options['userid']
		
		@accept      = 'application/json'
		@credentials = {}
		
		login
		create_connection
		status
	end
	
	##
	# Provides the current_temprature of the thermostat
	#
	# @return [Integer] the current temperature
	def current_temperature
		current_status = status
		temp_out(current_status['shared'][@serial]['current_temperature'])
	end
	
	##
	# Sets the fan to auto|off|on
	#
	# @param [String] state to set the fan
	#
	# @return [Boolean] true if successful
	def set_fan(state)
		resource = "/v2/put/device.#{@serial}"
		
		response = @connection.post resource do |request|
			request.headers['Content-Type'] = 'application/json'
			request.body = { :fan_mode => state }.to_json
		end
		
		raise RuntimeError, response.body if response.status != 200
		return true
	end
	
	##
	# Sets the target temperature of the thermostat
	#
	# @param [Integer] temp to set
	# 
	# @return [Boolean] true if successful
	def set_temperature(temp)
		resource = "/v2/put/shared.#{@serial}"
		
		response = @connection.post resource do |request|
			request.headers['Content-Type'] = 'application/json'
			request.body = { :target_change_pending => true, 
				               :target_temperature    => temp_in(temp.to_i) }.to_json
		end
		
		raise RuntimeError, response.body if response.status != 200
		return true
	end
	
	##
	# Returns the current state of the thermostat
	#
	# @return [Hash] hash of the current state of the thermostat
	def status
		resource = "/v2/mobile/user.#{@credentials['userid']}"
		
		current_status = JSON.parse(@connection.get(resource).body)
		set_serial(current_status) if @serial.nil?
		
		current_status
	end
	
	private
	
	##
	# Creates the connection with the transport_url obtained after login
	def create_connection
		@connection = Faraday.new(:url => @credentials['urls']['transport_url']) do |faraday|
			faraday.headers['Accept']                = @accept
			faraday.headers['user-agent']            = @options[:user_agent]
			faraday.headers['Authorization']         = "Basic #{@credentials['access_token']}" 
			faraday.headers['X-nl-user-id']          = @userid
			faraday.headers['X-nl-protocol-version'] = "1"
			faraday.adapter                          Faraday.default_adapter
		end
	end
	
	##
	# Logins into the service and sets the credentials
	def login
		resource = "/user/login"
		
		connection = Faraday.new(:url => @options[:base_url]) do |faraday|
			faraday.headers['Accept']     = @accept
			faraday.headers['user-agent'] = @options[:user_agent]
			faraday.adapter               Faraday.default_adapter
		end
		
		response = connection.get resource do |request|
			request.params['username'] = @options[:username]
			request.params['password'] = @options[:password]
		end
		
		raise RuntimeError, 'Could not login' if response.body.nil?
		
		@credentials = JSON.parse(response.body)
		@userid      = @credentials['userid'] if @userid.nil?
	end
	
	##
	# Sets the serial number of the device 
	#
	# @param [Hash] current_status of the thermostat
	def set_serial(current_status)
		current_status['structure'].each do |k, v| 
			@serial = v['devices'][@options[:index]].split('.')[1]
		end
	end
	
	##
	# Converts the value into Celcius if in Farenheit
	#
	# @param [Integer] temp to convert
	#
	# @return [Integer] the converted temprature
	def temp_in(temp)
		if @options[:units] == "F"
			(temp - 32.0) / 1.8
		else
			temp
		end
	end
	
	##
	# Converts the value into Farenheit if in Celsius
	#
	# @param [Integer] temp to convert
	#
	# @return [Integer] the converted temprature
	def temp_out(temp)
		if @options[:units] == "F"
			((temp * 1.8) + 32.0).round
		else
			temp
		end
	end
end