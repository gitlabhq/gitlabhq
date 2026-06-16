# frozen_string_literal: true

module Organizations
  module ShardingTestModel
    TABLE_NAME = '_test_sharding_models'

    def self.create_test_model(sharding_keys: {})
      ensure_table_exists

      # Define the model class with a proper name
      model_class = Class.new(ApplicationRecord)
      model_class.define_singleton_method(:name) { 'ShardingTestModel' }

      model_class.class_eval do
        self.table_name = TABLE_NAME
        include Organizations::Sharding

        # Define associations with explicit class names
        # `def organization` is also defined in Organizations::Sharding concern, we only
        # want to override that if we have organization id as a foreign key
        if sharding_keys.value?('organizations')
          belongs_to :organization, class_name: '::Organizations::Organization', optional: true
        end

        belongs_to :namespace, class_name: '::Namespace', optional: true
        belongs_to :project, class_name: '::Project', optional: true
        belongs_to :user, class_name: '::User', optional: true
      end

      # Store sharding_keys
      model_class.define_singleton_method(:sharding_keys) { sharding_keys }

      model_class
    end

    def self.ensure_table_exists
      return if ApplicationRecord.connection.table_exists?(TABLE_NAME)

      ApplicationRecord.connection.create_table(TABLE_NAME, temporary: false) do |t|
        t.bigint :organization_id
        t.bigint :namespace_id
        t.bigint :project_id
        t.bigint :user_id
        t.timestamps
      end
    end

    def self.cleanup_table
      ApplicationRecord.connection.drop_table(TABLE_NAME, if_exists: true)
    end
  end
end
