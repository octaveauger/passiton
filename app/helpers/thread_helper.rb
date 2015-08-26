module ThreadHelper

	# Takes a string containing one or several emails and returns an array of emails
	def explode_emails(emails)
		emails.split(',').map { |s| s.squish }
	end

	# Takes a string containing a unique email and returns a hash with the name, domain name and email address
	def parse_email(email)
		parsed_email = { name: '', domain: '', email: '', company:'' }
		if !email.index('<').nil?
			parsed_email[:name] = email[0..(email.index('<')-1)].squish
			parsed_email[:email] = between(email, { start: '<', end: '>' })
		else
			parsed_email[:email] = email
			parsed_email[:name] = email[0..(email.index('@')-1)].gsub('.', ' ').split.map(&:capitalize).join(' ')
		end
		parsed_email[:domain] = between(parsed_email[:email], { start: '@' }).capitalize
		parsed_email[:company] = between(parsed_email[:email], { start: '@' , end: '.'})
		parsed_email
	end

	# Returns the bootstrap class for the glyphicon if the mimetype is known, or a default file style otherwise
	def mimetype_visual(mimetype)
		visuals = {
			'application/pdf' => 'glyphicon-file',
			'application/msword' => 'glyphicon-file',
			'text/csv' => 'glyphicon-file',
			'image/png' => 'glyphicon-picture'
		}
		default = 'glyphicon-file'
		visuals[mimetype].present? ? visuals[mimetype] : default
	end
end
