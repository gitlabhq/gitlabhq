# frozen_string_literal: true

module DbCleaner
  def delete_from_all_tables!(except: [])
    except << 'ar_internal_metadata'

    DatabaseCleaner.clean_with(:deletion, cache_tables: false, except: except)
  end

  def deletion_except_tables
    []
  end

  def setup_database_cleaner
    DatabaseCleaner[:active_record, { connection: ActiveRecord::Base }]
  end
end

DbCleaner.prepend_mod_with('DbCleaner')
