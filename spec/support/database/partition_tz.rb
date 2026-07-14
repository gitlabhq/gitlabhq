# frozen_string_literal: true

# Manages the throwaway side connection pool to the non-UTC Postgres instance
# (`postgres-tz`) used by the `:partition_tz`-tagged partition export/import
# guard specs.
#
# The pool is established in a `before(:context)` hook and removed in an
# `after(:context)` hook. This is deliberate: `establish_connection` raises if
# called while a database transaction is open, and each example runs inside a
# transaction (transactional tests). `before(:context)` runs before that
# per-example transaction is opened, so establishing the pool there avoids the
# open-transaction guard. Per-example code then just fetches the connection via
# the `tz_connection` helper.
RSpec.configure do |config|
  config.before(:context, :partition_tz) do
    next unless ENV['POSTGRES_TZ_HOST'].present?

    ::Database::MultipleDatabasesHelpers::PartitionTzConnection.establish_tz_pool!

    # Create the minimal schema (gitlab_partitions_dynamic + two pure pg_catalog
    # views) that the no-silent-corruption proof needs so
    # `PartitionExporter#export` can run against `postgres-tz` and observe a real
    # boundary. The guard-raise examples do not need this -- they raise before
    # any table access -- but creating it once here is harmless for them and
    # keeps the SQL in one place.
    ::Database::MultipleDatabasesHelpers::PartitionTzConnection.setup_partition_schema!
  end

  config.after(:context, :partition_tz) do
    ::Database::MultipleDatabasesHelpers::PartitionTzConnection.teardown_tz_pool!
  end
end
