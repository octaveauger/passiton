class Label < ActiveRecord::Base
  belongs_to :user

  def self.sync_gmail(user)
  	client = Gmail.new(user.tokens.last.fresh_token)
	labels = client.list_labels
	current_labels = user.labels.all
	labels['labels'].each do |label|
		if (label['type'] != 'system' or ['STARRED', 'IMPORTANT'].include? label['id']) and !current_labels.where(label_id: label['id']).any?
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
