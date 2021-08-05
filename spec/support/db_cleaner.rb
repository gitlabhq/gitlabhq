# frozen_string_literal: true

module DbCleaner
  def all_connection_classes
    ::ActiveRecord::Base.connection_handler.connection_pool_names.map(&:constantize)
  end

  def delete_from_all_tables!(except: [])
    except << 'ar_internal_metadata'

    DatabaseCleaner.clean_with(:deletion, cache_tables: false, except: except)
  end

  def deletion_except_tables
    []
  end

  def setup_database_cleaner
    all_connection_classes.each do |connection_class|
      DatabaseCleaner[:active_record, { connection: connection_class }]
    end
  end
end

DbCleaner.prepend_mod_with('DbCleaner')
