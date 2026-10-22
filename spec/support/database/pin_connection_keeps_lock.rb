# frozen_string_literal: true

# Backport of https://github.com/rails/rails/pull/59045. A nested pin_connection!(true)
# (before_all plus the per-example pin) replaces the connection's monitor, so a Puma or
# Action Cable thread still holding the old one shares the PG connection with the example.
# Remove once our Rails version includes the fix.
if ActiveRecord.gem_version >= Gem::Version.new('8.2.0.alpha')
  raise 'rails/rails#59045 is in this Rails version. Delete spec/support/database/pin_connection_keeps_lock.rb'
end

unless ActiveRecord::ConnectionAdapters::ConnectionPool.method_defined?(:pin_connection!)
  raise 'ActiveRecord::ConnectionAdapters::ConnectionPool#pin_connection! no longer exists. ' \
    'See spec/support/database/pin_connection_keeps_lock.rb'
end

module Database
  module PinConnectionKeepsLock
    def pin_connection!(lock_thread)
      return super(false) if lock_thread && connection_lock_installed?

      super
    end

    private

    def connection_lock_installed?
      return false unless @pinned_connection

      lock = @pinned_connection.lock
      !lock.equal?(ActiveSupport::Concurrency::NullLock)
    end
  end
end

ActiveRecord::ConnectionAdapters::ConnectionPool.prepend(Database::PinConnectionKeepsLock)
