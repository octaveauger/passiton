module ApplicationHelper
  
  #Returns a substring between opts[:start] and either opts[:end] or, if not present, the end of the string (removes first all multiple whitespaces and \n); nil if not found
  def between string, opts
    string.squish!
	charStart = string.index(opts[:start]) + opts[:start].length
	opts[:end].nil? ? charEnd = string.length : charEnd = string[charStart..string.length].index(opts[:end]) + charStart - 1
    charStart.nil? or charEnd.nil? ? nil : string[charStart..charEnd]
  end

  # Checks if we are on production (based on URL_HOST env variable, not Rails environment as staging also behaves as production for Rails)
  def we_are_on_production
  	ENV['URL_HOST'] == 'https://justpassiton.herokuapp.com'
  end

end
