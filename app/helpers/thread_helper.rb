module ThreadHelper

	# Takes a string containing one or several emails and returns an array of emails
	def explode_emails(emails)
		exploded = []
		substring = ''
		# Go character by character
		emails.split("").each do |c|
			# As long as character not comma, save in temp string
			if c != ','
				substring += c
			# If character is comma
			else
				# If @ found in temp string: push into exploded array and start new string
				if !substring.index('@').nil?
					exploded.push(substring)
					substring = ''
				# Otherwise keep going
				else
					substring += c
				end
			end
		end
		# If end of string: push into exploded array
		exploded.push(substring)
		exploded
	end

	# Takes a string containing a unique email and returns a hash with the name, domain name and email address
	def parse_email(email)
		parsed_email = { name: '', first_name: '', last_name: '', domain: '', email: '', company:'' }
		if !email.index('<').nil?
			parsed_email[:name] = email[0..(email.index('<')-1)].squish
			parsed_email[:email] = between(email, { start: '<', end: '>' })
		else
			parsed_email[:email] = email
			parsed_email[:name] = email[0..(email.index('@')-1)].gsub('.', ' ').split.map(&:capitalize).join(' ')
		end
		parsed_email[:domain] = between(parsed_email[:email], { start: '@' }).capitalize
		parsed_email[:company] = between(parsed_email[:email], { start: '@' , end: '.'})
		parsed_email[:name].gsub!('"','')
		if parsed_email[:name].index(' ').nil?
			parsed_email[:last_name] = parsed_email[:name]
		else
			parsed_email[:first_name] = parsed_email[:name][0..parsed_email[:name].index(' ')-1]
			parsed_email[:last_name] = parsed_email[:name][parsed_email[:name].index(' ')+1..-1]
		end
		parsed_email[:email].downcase!
		parsed_email
	end

	# Returns the bootstrap class for the glyphicon if the mimetype is known, or a default file style otherwise
	def glyphicon_file(type)
		if %w(PNG GIF JPG).include? type
			'glyphicon glyphicon-picture'
		elsif type == 'ICS'
			'glyphicon glyphicon-calendar'
		elsif %w(DOC DOCX PDF).include? type
			'glyphicon glyphicon-list-alt'
		elsif %w(CSV XLS XLSX).include? type
			'glyphicon glyphicon-th'
		elsif type == 'ZIP'
			'glyphicon glyphicon-folder-close'
		else
			'glyphicon glyphicon-file'
		end
	end

	# Returns the boostrap class for the glyphicon of the Gmail label
	def glyphicon_label(label)
		if label[:label_type] == 'system'
			if label[:name] == 'IMPORTANT'
				'<span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>'
			elsif label[:name] == 'STARRED'
				'<span class="glyphicon glyphicon-star warning" aria-hidden="true"></span>'
			else
				'<span class="label label-default">' + label[:name] + '</span>'
			end
		else
			'<span class="label label-primary">' + label[:name] + '</span>'
		end
	end
end
