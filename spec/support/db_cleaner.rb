module DbCleaner
  def deletion_except_tables
    []
  end

  def setup_database_cleaner
    DatabaseCleaner[:active_record, { connection: ActiveRecord::Base }]
  end
end
