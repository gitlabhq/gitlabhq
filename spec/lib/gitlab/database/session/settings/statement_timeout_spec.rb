# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Session::Settings::StatementTimeout, :delete, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }

  def current_timeout
    connection.select_value('SHOW statement_timeout')
  end

  around do |example|
    original = current_timeout
    connection.execute("SET statement_timeout TO '15s'")
    example.run
  ensure
    connection.execute("SET statement_timeout TO #{connection.quote(original)}")
  end

  describe '.with' do
    it 'sets statement_timeout inside the block and restores it afterwards' do
      described_class.with(connection, '2h') do
        expect(current_timeout).to eq('2h')
      end

      expect(current_timeout).to eq('15s')
    end

    it 'treats an integer as milliseconds' do
      described_class.with(connection, 5000) do
        expect(current_timeout).to eq('5s')
      end
    end

    it 'disables statement_timeout for a zero timeout' do
      described_class.with(connection, 0) do
        expect(current_timeout).to eq('0')
      end

      expect(current_timeout).to eq('15s')
    end

    it 'restores statement_timeout when the block raises' do
      expect { described_class.with(connection, 0) { raise 'boom' } }.to raise_error('boom')

      expect(current_timeout).to eq('15s')
    end
  end
end
