module ApplicationHelper
  #Returns a substring between opts[:start] and either opts[:end] or, if not present, the end of the string (removes first all multiple whitespaces and \n); nil if not found
  def between string, opts
    string.squish!
	charStart = string.index(opts[:start]) + opts[:start].length
	opts[:end].nil? ? charEnd = string.length : charEnd = string.index(opts[:end]) - 1
    puts charEnd
    charStart.nil? or charEnd.nil? ? nil : string[charStart..charEnd]
  end
end
