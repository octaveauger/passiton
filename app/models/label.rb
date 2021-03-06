class Label < ActiveRecord::Base
  belongs_to :user

  def self.sync_gmail(user)
  	useless_labels = ['boomerang', 'boomerang-returned'] # these label names won't be saved
    begin
      client = Gmail.new(user.tokens.last.fresh_token, user.email)
    rescue => e
      authorisation.granter.register_oauth_cancelled
      return false
    end
    	
  	labels = client.list_labels
  	current_labels = user.labels.all
  	labels['labels'].each do |label|
  		if (label['type'] != 'system' or ['STARRED', 'IMPORTANT'].include? label['id']) and !current_labels.where(label_id: label['id']).any? and !useless_labels.include? label['name'].downcase
  			user.labels.create(
  				label_id: label['id'],
  				name: label['name'],
  				label_type: label['type']
  			)
  		end
  	end
  end

  def self.to_array(user)
  	list = []
  	user.labels.all.each do |label|
  		list.push(label.label_id)
  	end
  	list
  end
end
