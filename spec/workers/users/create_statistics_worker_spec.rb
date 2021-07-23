# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CreateStatisticsWorker do
  describe '#perform' do
    subject { described_class.new.perform }

    before do
      allow(UsersStatistics.connection).to receive(:transaction_open?).and_return(false)
    end

    context 'when successful' do
      it 'create an users statistics entry' do
        expect { subject }.to change { UsersStatistics.count }.from(0).to(1)
      end
    end

    context 'when unsuccessful' do
      it 'logs an error' do
        users_statistics = build(:users_statistics)
        users_statistics.errors.add(:base, 'This is an error')
        exception = ActiveRecord::RecordInvalid.new(users_statistics)

        allow(UsersStatistics).to receive(:create_current_stats!).and_raise(exception)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception).and_call_original

        subject
      end
    end
  end
end
