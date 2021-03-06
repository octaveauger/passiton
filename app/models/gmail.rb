class Gmail
	##############################################
	# References:
	# Ruby library: https://developers.google.com/gmail/api/quickstart/ruby
	# Scope: https://support.google.com/mail/answer/7190?hl=en
	##############################################

	def initialize(token, user_email = 'me')
		Google::APIClient.logger.level = Logger::DEBUG
		@client = Google::APIClient.new( {
			application_name: ENV['GMAIL_APPLICATION_NAME']
			})
		@client.authorization.access_token = token
		@service = @client.discovered_api('gmail')
		Rails.logger.info('Gmail client initialised')
		@default_options = {
			parameters: { 'userId' => user_email },
			headers: { 'Content-Type' => 'application/json' }
		}
	end

	# Grab all threads page by page and returns an array with each thread as a hash
	def list_threads(scope)
		Rails.logger.info('Gmail list threads called - scope: ' + scope)
		threads = []
		next_page_token = nil
		loop do
			results = list_threads_page(scope, next_page_token)
			threads += results['threads'] if results['threads']
			next_page_token = results['nextPageToken']
			break if results['nextPageToken'].nil?
		end
		Rails.logger.info('Gmail list threads complete - results count: ' + threads.count.to_s)
		notify_slack(scope) if threads.count == 0
		threads
	end

	# Grab a specific page of threads
	def list_threads_page(scope, page)
		opts = @default_options.merge(api_method: @service.users.threads.list)
		opts[:parameters]['q'] = scope
		opts[:parameters][:pageToken] = page unless page.nil?
		execute(opts)
	end

	def get_thread(id)
		opts = @default_options.merge(api_method: @service.users.threads.get)
		opts[:parameters]['id'] = id
		opts[:parameters]['format'] = 'full'
		execute(opts)
	end

	# Grab all messages page by page
	def list_messages(scope)
		Rails.logger.info('Gmail list messages called - scope: ' + scope)
		messages = []
		next_page_token = nil
		loop do
			results = list_messages_page(scope, next_page_token)
			messages += results['messages'] if results['messages']
			next_page_token = results['nextPageToken']
			break if results['nextPageToken'].nil?
		end
		Rails.logger.info('Gmail list messages complete - results count: ' + messages.count.to_s)
		notify_slack(scope) if messages.count == 0
		messages
	end

	def list_messages_page(scope, page)
		opts = @default_options.merge(:api_method => @service.users.messages.list)
		opts[:parameters]['q'] = scope
		opts[:parameters][:pageToken] = page unless page.nil?
		execute(opts)
	end

	def download_attachment(messageId, attachmentId)
		opts = @default_options.merge(api_method: @service.users.messages.attachments.get)
		opts[:parameters]['id'] = attachmentId
		opts[:parameters]['messageId'] = messageId
		execute(opts)
	end

	def list_labels
		opts = @default_options.merge(:api_method => @service.users.labels.list)
		execute(opts)
	end

	def notify_slack(scope)
		if !Rails.env.development?
			notifier = Slack::Notifier.new(ENV['SLACK_WEBHOOK_EXCEPTION'])
			notifier.ping('Gmail returned 0 result for scope: ' + scope)
		end
	end

	private

		def execute(opts)
			JSON.parse(@client.execute(opts).response.body)
		end

end