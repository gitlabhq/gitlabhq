require 'spec_helper'

describe Ci::Status do
  describe '.get_status' do
    subject { described_class.get_status(statuses) }
    
    [:ci_build, :generic_commit_status].each do |type|
      context "for #{type}" do
        context 'all successful' do
          let(:statuses) { Array.new(2) { create(type, status: :success) } }
          it { is_expected.to eq 'success' }
        end

        context 'at least one failed' do
          let(:statuses) { [create(type, status: :success), create(type, status: :failed)] }
          it { is_expected.to eq 'failed' }
        end

        context 'at least one running' do
          let(:statuses) { [create(type, status: :success), create(type, status: :running)] }
          it { is_expected.to eq 'running' }
        end

        context 'at least one pending' do
          let(:statuses) { [create(type, status: :success), create(type, status: :pending)] }
          it { is_expected.to eq 'running' }
        end

        context 'success and failed but allowed to fail' do
          let(:statuses) { [create(type, status: :success), create(type, status: :failed, allow_failure: true)] }
          it { is_expected.to eq 'success' }
        end

        context 'one failed but allowed to fail' do
          let(:statuses) { [create(type, status: :failed, allow_failure: true)] }
          it { is_expected.to eq 'success' }
        end
      end
    end
  end
end
