# frozen_string_literal: true

module Database
  module DatabaseHelpers
    # In order to directly work with views using factories,
    # we can swapout the view for a table of identical structure.
    def swapout_view_for_table(view)
      ActiveRecord::Base.connection.execute(<<~SQL.squish)
        CREATE TABLE #{view}_copy (LIKE #{view});
        DROP VIEW #{view};
        ALTER TABLE #{view}_copy RENAME TO #{view};
      SQL
    end

    # Set statement timeout temporarily.
    # Useful when testing query timeouts.
    #
    # Note that this method cannot restore the timeout if a query
    # was canceled due to e.g. a statement timeout.
    # Refrain from using this transaction in these situations.
    #
    # @param timeout - Statement timeout in seconds
    #
    # Example:
    #
    #   with_statement_timeout(0.1) do
    #     model.select('pg_sleep(0.11)')
    #   end
    def with_statement_timeout(timeout)
      # Force a positive value and a minimum of 1ms for very small values.
      timeout = (timeout * 1000).abs.ceil

      raise ArgumentError, 'Using a timeout of `0` means to disable statement timeout.' if timeout == 0

      previous_timeout = ActiveRecord::Base.connection
        .exec_query('SHOW statement_timeout')[0].fetch('statement_timeout')

      set_statement_timeout("#{timeout}ms")

      yield
    ensure
      begin
        set_statement_timeout(previous_timeout)
      rescue ActiveRecord::StatementInvalid
        # After a transaction was canceled/aborted due to e.g. a statement
        # timeout commands are ignored and will raise in PG::InFailedSqlTransaction.
        # We can safely ignore this error because the statement timeout was set
        # for the currrent transaction which will be closed anyway.
      end
    end

    # Set statement timeout for the current transaction.
    #
    # Note, that it does not restore the previous statement timeout.
    # Use `with_statement_timeout` instead.
    #
    # @param timeout - Statement timeout in seconds
    #
    # Example:
    #
    #   set_statement_timeout(0.1)
    #   model.select('pg_sleep(0.11)')
    def set_statement_timeout(timeout)
      ActiveRecord::Base.connection.execute(
        format(%(SET LOCAL statement_timeout = '%s'), timeout)
      )
    end
  end
end
