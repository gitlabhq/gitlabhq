# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuted do
  it_behaves_like 'deduplicating jobs when scheduling', :until_executed do
    describe '#perform' do
      let(:proc) { -> {} }

      it 'deletes the lock after executing' do
        expect(proc).to receive(:call).ordered
        expect(fake_duplicate_job).to receive(:delete!).ordered

        strategy.perform({}) do
          proc.call
        end
      end
    end
  end
end
