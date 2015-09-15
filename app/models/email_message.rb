class EmailMessage < ActiveRecord::Base
  belongs_to :email_thread
  has_many :message_attachments
  has_many :message_participants
  has_many :participants, through: :message_participants

  # Returns participants with a delivery in: 'to', 'from', 'cc', 'bcc'
  def participants_with_delivery(delivery)
    self.participants.joins(:message_participants).where('message_participants.delivery = ?', delivery).uniq
  end

  # Returns a decoded plain text body (use simple_format xxx in the view)
  def body_text
  	Base64.urlsafe_decode64(super).force_encoding("UTF-8")
  end

  # Returns a decoded html body
  def body_html
  	clean_html(Base64.urlsafe_decode64(super).html_safe.force_encoding("UTF-8"))
  end

  # Removes html formatting that adds too much empty space and extra lines
  def clean_html(html)

    # Removes special styling from Outlook
    html.gsub!(/<head> .* <\/head>/,"")
    html.gsub!(/<body style=.*">/,"<body>")
    html.gsub!(/<span style=.*">/,"")

    noko = Nokogiri::HTML(html)
    office_style = noko.at_css('head')
    if !office_style.nil?
      office_style.remove
      html = noko.to_html
    end

    html.gsub!(/(font-size: (\d{1,2}|\d{1,2}.\d{1,})px;)|(font size="\d{1,}")/,"") #removes any style that tries to set a different font size
    html
  end

  # Returns the main part of the email and (if any) the expanded part which is all past emails linked in the body
  def body_html_sections
    sections = { main: '', expanded: '' }
    regexes = [
      /<p.*>Le \d{2}\/\d{2}\/\d{4} \d{2}:\d{2}, .* \ba écrit\b/i,                    #Le 22/07/2015 18:09, Octave Auger a écrit :
      /<p.*>On .*, \d{2} .* \d{4} \bat\b \d{2}:\d{2}, .* \bwrote\b/i,                #On Wednesday, 10 June 2015 at 13:54, Jessie Giladi wrote:
      /<p.*>On .*, \w{3} \d{2}, \d{4} \bat\b \d{2}:\d{2} \w{2}, .* \bwrote\b/i,      #On Mon, Jul 13, 2015 at 10:49 PM, Octave Auger octave.auger@test.com wrote:
      /On .*, \d{4}, \bat\b \d{2}:\d{2}, .* \bwrote\b/i,                             #On Jun 30, 2015, at 08:21, Julien Balmont <julien@1001menus.com> wrote:
      /\d{4}-\d{2}-\d{2} \d{1,2}:\d{2} \bGMT\b.* <.*@.*\..*>:/i                      #2015-07-08 17:28 GMT+02:00 Amaury de Closset <amaury@gocardless.com>:
    ]
    regex = Regexp.union(regexes)

    #This needs to be changed to prioritise the first occurence of
    #gmail_quote over regex

    # First we try with well enclosed divs if gmail recognised a quote
    email = Nokogiri::HTML(self.body_html)
    expanded = email.at_css('.gmail_quote')

    # Need to correct to detect what comes first the regexes or gmail_quote

    if !expanded.nil?
      sections[:expanded] = expanded.to_html
      expanded.remove
      sections[:main] = email.to_html
    else # Now we start with regexes as we couldn't find a well enclosed div
      separator = self.body_html.index regex
      if !separator.nil?
        sections[:main] = self.body_html[0..separator-1]
        sections[:expanded] = self.body_html[separator..-1]
      else # Couldn't find anything, there might not be any expanded emails
        sections[:main] = self.body_html
      end
    end
    sections[:main].gsub!(/<!DOCTYPE.*>/, "")
    sections
  end

  # Returns the main part of the email and (if any) the expanded part which is all past emails linked in the body
  def body_text_sections
    sections = { main: '', expanded: '' }
    # http://www.cheatography.com/davechild/cheat-sheets/regular-expressions/
    regexes = [
      /\bLe\b \d{2}\/\d{2}\/\d{4} \d{2}:\d{2}, .* \ba écrit\b/i,                    #Le 22/07/2015 18:09, Octave Auger a écrit :
      /\bOn\b .*, \d{2} .* \d{4} \bat\b \d{2}:\d{2}, .* \bwrote\b/i,                #On Wednesday, 10 June 2015 at 13:54, Jessie Giladi wrote:
      /\bOn\b .*, \w{3} \d{2}, \d{4} \bat\b \d{2}:\d{2} \w{2}, .* \bwrote\b/i ,     #On Mon, Jul 13, 2015 at 10:49 PM, Octave Auger octave.auger@test.com wrote:
      /On .*, \d{4}, \bat\b \d{2}:\d{2}, .* \bwrote\b/i,                            #On Jun 30, 2015, at 08:21, Julien Balmont <julien@1001menus.com> wrote:
      /\d{4}-\d{2}-\d{2} \d{1,2}:\d{2} \bGMT\b.* <.*@.*\..*>:/i                     #2015-07-08 17:28 GMT+02:00 Amaury de Closset <amaury@gocardless.com>:
    ]
    regex = Regexp.union(regexes)

    separator = self.body_text.index regex
    if !separator.nil?
      sections[:main] = self.body_text[0..separator-1]
      sections[:expanded] = self.body_text[separator..-1]
    else
      sections[:main] = self.body_text
    end
    sections
  end
end
