module DatabaseConnectionHelpers
  def run_with_new_database_connection
    pool = ActiveRecord::Base.connection_pool
    conn = pool.checkout
    yield conn
  ensure
    pool.checkin(conn)
  end
end
