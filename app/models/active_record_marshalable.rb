module ActiveRecordMarshalable
  def marshal_dump
    [attributes, self.association_cache, instance_variable_get(:@new_record)]
  end

  def marshal_load data
    send :initialize, data[0]
    instance_variable_set :@association_cache, data[1]
    instance_variable_set :@new_record, data[2]
  end
end
