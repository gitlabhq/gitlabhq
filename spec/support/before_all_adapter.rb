# frozen_string_literal: true

class BeforeAllAdapter # rubocop:disable Gitlab/NamespacedClass
  def self.all_connection_pools
    ::ActiveRecord::Base.connection_handler.all_connection_pools
  end

  def self.begin_transaction
    self.all_connection_pools.each do |connection_pool|
      connection_pool.connection.begin_transaction(joinable: false)
    end
  end

  def self.rollback_transaction
    self.all_connection_pools.each do |connection_pool|
      if connection_pool.connection.open_transactions.zero?
        warn "!!! before_all transaction has been already rollbacked and " \
              "could work incorrectly"
        next
      end

      connection_pool.connection.rollback_transaction
    end
  end
end

TestProf::BeforeAll.adapter = ::BeforeAllAdapter
