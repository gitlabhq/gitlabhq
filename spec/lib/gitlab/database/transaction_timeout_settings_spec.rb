# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TransactionTimeoutSettings, feature_category: :cell do
  let(:connection) { ActiveRecord::Base.connection }

  subject { described_class.new(connection) }

  after(:all) do
    described_class.new(ActiveRecord::Base.connection).restore_timeouts
  end

  describe '#disable_timeouts' do
    it 'sets timeouts to 0' do
      subject.disable_timeouts

      expect(current_timeout).to eq("0")
    end
  end

  describe '#restore_timeouts' do
    before do
      subject.disable_timeouts
    end

    it 'resets value' do
      expect(connection).to receive(:execute).with('RESET idle_in_transaction_session_timeout').and_call_original

      subject.restore_timeouts
    end
  end

  def current_timeout
    connection.execute("show idle_in_transaction_session_timeout").first['idle_in_transaction_session_timeout']
  end
end
