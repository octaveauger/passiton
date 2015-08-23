class Gmail
	##############################################
	# References:
	# Ruby library: https://developers.google.com/gmail/api/quickstart/ruby
	# Scope: https://support.google.com/mail/answer/7190?hl=en
	##############################################

	def initialize(token)
		@client = Google::APIClient.new
		@client.authorization.access_token = token
		@service = @client.discovered_api('gmail')
	end

	DEFAULT_OPTIONS = {
		parameters: { 'userId' => 'me' },
		headers: { 'Content-Type' => 'application/json' }
	}

	def list_threads(scope)
		opts = DEFAULT_OPTIONS.merge(api_method: @service.users.threads.list)
		opts[:parameters]['q'] = scope
		execute(opts)
	end

	def get_thread(id)
		opts = DEFAULT_OPTIONS.merge(api_method: @service.users.threads.get)
		opts[:parameters]['id'] = id
		opts[:parameters]['format'] = 'full'
		execute(opts)
	end

	def list_messages
		opts = DEFAULT_OPTIONS.merge(:api_method => @service.users.messages.list)
		execute(opts)
	end

	private

		def execute(opts)
			JSON.parse(@client.execute(opts).response.body)
		end

end