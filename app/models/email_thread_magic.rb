class EmailThreadMagic
    attr_accessor :thread_id, :snippet, :history_id

    def initialize(attributes = {})
        attributes.each do |name, value|
        send("#{name}=", value)
        end
    end
end