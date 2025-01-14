# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuting do
  it_behaves_like 'deduplicating jobs when scheduling', :until_executing do
    describe '#perform' do
      let(:proc) { -> {} }

      before do
        allow(fake_duplicate_job).to receive(:latest_wal_locations).and_return({})
      end

      it 'deletes the lock before executing' do
        expect(fake_duplicate_job).to receive(:delete!).ordered
        expect(proc).to receive(:call).ordered

        strategy.perform({}) do
          proc.call
        end
      end
    end
  end
end
