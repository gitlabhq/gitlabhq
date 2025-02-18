# frozen_string_literal: true

RSpec.configure do |config|
  lock_recorder = Gitlab::Database::LockRecorder.instance

  config.before(:all, :lock_recorder) do
    ApplicationRecord.alias_method :old_reload, :reload
    ApplicationRecord.define_method(:reload) do |args = {}|
      locked_obj = old_reload(args)

      if lock_recorder.recording? && args.has_key?(:lock)
        lock_recorder.add(locked_obj, normalized_lock_type(args[:lock]))
      end

      locked_obj
    end

    ActiveRecord::Relation.alias_method :old_load, :load
    ActiveRecord::Relation.define_method(:load) do |&block|
      loaded_objs = old_load(&block)

      if lock_recorder.recording? && values.has_key?(:lock)
        @records.each do |record|
          lock_recorder.add(record, normalized_lock_type(values[:lock]))
        end
      end

      loaded_objs
    end
  end

  config.after(:each, :lock_recorder) do
    lock_recorder.stop
    lock_recorder.clear
  end

  config.after(:all, :lock_recorder) do
    ApplicationRecord.alias_method :record_reload, :reload
    ApplicationRecord.alias_method :reload, :old_reload
    ApplicationRecord.remove_method :record_reload

    ActiveRecord::Relation.alias_method :record_load, :load
    ActiveRecord::Relation.alias_method :load, :old_load
    ActiveRecord::Relation.remove_method :record_load
  end

  def normalized_lock_type(lock_type)
    if lock_type == true
      'FOR UPDATE'
    else
      lock_type
    end
  end
end
