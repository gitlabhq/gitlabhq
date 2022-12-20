# frozen_string_literal: true

module TestProfBeforeAllAdapter
  module MultipleDatabaseAdapter
    def self.all_connection_classes
      @all_connection_classes ||= [ActiveRecord::Base] + ActiveRecord::Base.descendants.select(&:connection_class?) # rubocop: disable Database/MultipleDatabases
    end

    def self.begin_transaction
      self.all_connection_classes.each do |connection_class|
        connection_class.connection.begin_transaction(joinable: false)
      end
    end

    def self.rollback_transaction
      self.all_connection_classes.each do |connection_class|
        if connection_class.connection.open_transactions.zero?
          warn "!!! before_all transaction has been already rollbacked and " \
                "could work incorrectly"
          next
        end

        connection_class.connection.rollback_transaction
      end
    end
  end

  # This class is required so we can disable transactions on migration specs
  module NoTransactionAdapter
    def self.begin_transaction; end

    def self.rollback_transaction; end
  end

  def self.default_adapter
    MultipleDatabaseAdapter
  end

  def self.no_transaction_adapter
    NoTransactionAdapter
  end
end

TestProf::BeforeAll.adapter = ::TestProfBeforeAllAdapter.default_adapter
