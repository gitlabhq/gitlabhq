# frozen_string_literal: true

module PreventCrossDatabaseModificationSpecHelpers
  delegate :with_cross_database_modification_prevented,
    :allow_cross_database_modification_within_transaction,
    to: :'::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification'
end

CROSS_DB_MODIFICATION_ALLOW_LIST = Set.new(YAML.load_file(File.join(__dir__, 'cross-database-modification-allowlist.yml'))).freeze

RSpec.configure do |config|
  config.include(PreventCrossDatabaseModificationSpecHelpers)

  # By default allow cross-modifications as we want to observe only transactions
  # within a specific block of execution which is defined be `before(:each)` and `after(:each)`
  config.before(:all) do
    ::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.suppress_in_rspec = true
  end

  # Using before and after blocks because the around block causes problems with the let_it_be
  # record creations. It makes an extra savepoint which breaks the transaction count logic.
  config.before do |example_file|
    ::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.suppress_in_rspec =
      CROSS_DB_MODIFICATION_ALLOW_LIST.include?(example_file.file_path_rerun_argument)
  end

  # Reset after execution to preferred state
  config.after do |example_file|
    ::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.suppress_in_rspec = true

    ::ApplicationRecord.gitlab_transactions_stack.clear
  end
end
