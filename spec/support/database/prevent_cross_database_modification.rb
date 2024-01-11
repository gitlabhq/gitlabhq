# frozen_string_literal: true

module Database
  module PreventCrossDatabaseModificationSpecHelpers
    delegate :with_cross_database_modification_prevented,
      :allow_cross_database_modification_within_transaction,
      to: :'::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification'
  end

  module AllowCrossDatabaseFactoryBotBuilt
    extend ActiveSupport::Concern

    attr_accessor :factory_bot_built

    prepended do
      around_create :_test_ignore_table_in_transaction, prepend: true, if: :factory_bot_built?

      def _test_ignore_table_in_transaction(&blk)
        Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
          [self.class.table_name], url: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130277', &blk
        )
      end
    end

    def factory_bot_built?
      return false unless Rails.env.test?

      !!factory_bot_built
    end

    private

    def ignore_cross_database_tables_if_factory_bot(tables, &blk)
      return super unless factory_bot_built?

      Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
        tables,
        url: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130277',
        &blk
      )
    end
  end
end

ActiveRecord::Base.prepend(Database::AllowCrossDatabaseFactoryBotBuilt)

CROSS_DB_MODIFICATION_ALLOW_LIST = Set.new(YAML.load_file(File.join(__dir__, 'cross-database-modification-allowlist.yml'))).freeze

RSpec.configure do |config|
  config.include(Database::PreventCrossDatabaseModificationSpecHelpers)

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
  config.after do |_example_file|
    ::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.suppress_in_rspec = true

    ::ApplicationRecord.gitlab_transactions_stack.clear
  end

  config.before(:suite) do
    ActiveSupport::Notifications.subscribe("factory_bot.run_factory") do |_name, _start, _finish, _id, payload|
      strategy = payload[:strategy]
      Thread.current[:factory_bot_objects] -= 1 if strategy == :create
    end
  end
end
