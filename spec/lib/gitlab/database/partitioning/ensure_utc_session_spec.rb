# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::EnsureUtcSession, feature_category: :database do
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

  let(:guard_class) do
    Class.new do
      include Gitlab::Database::Partitioning::EnsureUtcSession

      def initialize(connection)
        @connection = connection
      end

      def run!
        ensure_utc_session!
      end

      private

      attr_reader :connection
    end
  end

  subject(:guard) { guard_class.new(connection) }

  def stub_timezones(session:, reset_val:)
    allow(connection).to receive(:select_value).with('SHOW TIMEZONE').and_return(session)
    allow(connection).to receive(:select_value)
      .with("SELECT reset_val FROM pg_settings WHERE name = 'TimeZone'").and_return(reset_val)
  end

  context 'when both the session and the configured default are UTC' do
    it 'does not raise' do
      stub_timezones(session: 'UTC', reset_val: 'UTC')

      expect { guard.run! }.not_to raise_error
    end

    it 'normalizes UTC-equivalent values' do
      stub_timezones(session: 'Etc/UTC', reset_val: 'GMT')

      expect { guard.run! }.not_to raise_error
    end
  end

  context 'when the session TimeZone is not UTC' do
    it 'raises and names the session source' do
      stub_timezones(session: 'America/Los_Angeles', reset_val: 'UTC')

      expect { guard.run! }.to raise_error(ArgumentError, %r{session TimeZone to be UTC, got: America/Los_Angeles})
    end
  end

  context 'when the session is UTC but the configured default is not UTC' do
    it 'raises defensively and names the configured default source' do
      stub_timezones(session: 'UTC', reset_val: 'America/New_York')

      expect { guard.run! }
        .to raise_error(ArgumentError, %r{configured default TimeZone to be UTC, got: America/New_York})
    end
  end
end
