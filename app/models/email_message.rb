class EmailMessage < ActiveRecord::Base
  belongs_to :email_thread
  has_many :message_attachments

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
    html.gsub!(/\r\n<div><br>\r\n<\/div>/,"")
    html.gsub!(/(font-size: (\d{1,2}|\d{1,2}.\d{1,})px;)|(font size="\d{1,}")/,"") #removes any style that tries to set a different font size
    html
  end

  # Returns the main part of the email and (if any) the expanded part which is all past emails linked in the body
  def body_html_sections
    sections = { main: '', expanded: '' }
    regexes = [
      /<p.*>Le \d{2}\/\d{2}\/\d{4} \d{2}:\d{2}, .* \ba écrit\b/i,                    #Le 22/07/2015 18:09, Octave Auger a écrit :
      /<p.*>On .*, \d{2} .* \d{4} \bat\b \d{2}:\d{2}, .* \bwrote\b/i,                #On Wednesday, 10 June 2015 at 13:54, Jessie Giladi wrote:
      /<p.*>On .*, \w{3} \d{2}, \d{4} \bat\b \d{2}:\d{2} \w{2}, .* \bwrote\b/i       #On Mon, Jul 13, 2015 at 10:49 PM, Octave Auger octave.auger@test.com wrote:
    ]
    regex = Regexp.union(regexes)
    
    # First we try with well enclosed divs if gmail recognised a quote
    email = Nokogiri::HTML(self.body_html)
    expanded = email.at_css('.gmail_quote')

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
      /\bOn\b .*, \w{3} \d{2}, \d{4} \bat\b \d{2}:\d{2} \w{2}, .* \bwrote\b/i       #On Mon, Jul 13, 2015 at 10:49 PM, Octave Auger octave.auger@test.com wrote:
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
