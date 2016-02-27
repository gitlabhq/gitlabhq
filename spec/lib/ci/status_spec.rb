require 'spec_helper'

describe Ci::Status do
  describe '.get_status' do
    subject { described_class.get_status(statuses) }
    
    shared_examples 'build status summary' do
      context 'all successful' do
        let(:statuses) { Array.new(2) { create(type, status: :success) } }
        it { is_expected.to eq 'success' }
      end

      context 'at least one failed' do
        let(:statuses) do
          [create(type, status: :success), create(type, status: :failed)]
        end

        it { is_expected.to eq 'failed' }
      end

      context 'at least one running' do
        let(:statuses) do
          [create(type, status: :success), create(type, status: :running)]
        end

        it { is_expected.to eq 'running' }
      end

      context 'at least one pending' do
        let(:statuses) do
          [create(type, status: :success), create(type, status: :pending)]
        end

        it { is_expected.to eq 'running' }
      end

      context 'success and failed but allowed to fail' do
        let(:statuses) do
          [create(type, status: :success),
           create(type, status: :failed, allow_failure: true)]
        end

        it { is_expected.to eq 'success' }
      end

      context 'one failed but allowed to fail' do
        let(:statuses) { [create(type, status: :failed, allow_failure: true)] }
        it { is_expected.to eq 'success' }
      end

      context 'one finished and second running but allowed to fail' do
        let(:statuses) do
          [create(type, status: :success),
           create(type, status: :running, allow_failure: true)]
        end

        it { is_expected.to eq 'running' }
      end
    end

    context 'ci build statuses' do
      let(:type) { :ci_build }
      it_behaves_like 'build status summary'
    end

    context 'generic commit statuses' do
      let(:type) { :generic_commit_status }
      it_behaves_like 'build status summary'
    end
  end
end
