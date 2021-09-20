# frozen_string_literal: true

class BeforeAllAdapter # rubocop:disable Gitlab/NamespacedClass
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

TestProf::BeforeAll.adapter = ::BeforeAllAdapter
