# frozen_string_literal: true

RSpec.configure do |config|
  # Ensure database versions are memoized to prevent query counts from
  # being affected by version checks. Note that
  # Gitlab::Database.check_postgres_version_and_print_warning is called
  # at startup, but that generates its own
  # `Gitlab::Database::Reflection` so the result is not memoized by
  # callers of `ApplicationRecord.database.version`, such as
  [ApplicationRecord, ::Ci::ApplicationRecord].each { |record| record.database.version }

  config.around(:each, :reestablished_active_record_base) do |example|
    with_reestablished_active_record_base(reconnect: example.metadata.fetch(:reconnect, true)) do
      example.run
    end
  end

  config.around(:each, :add_ci_connection) do |example|
    with_added_ci_connection do
      example.run
    end
  end
end
