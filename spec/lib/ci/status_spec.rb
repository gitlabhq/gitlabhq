require 'spec_helper'

describe Ci::Status do
  describe '.get_status' do
    subject { described_class.get_status(builds) }

    context 'all builds successful' do
      let(:builds) { Array.new(2) { create(:ci_build, :success) } }
      it { is_expected.to eq 'success' }
    end

    context 'at least one build failed' do
      let(:builds) { [create(:ci_build, :success), create(:ci_build, :failed)] }
      it { is_expected.to eq 'failed' }
    end

    context 'at least one running' do
      let(:builds) { [create(:ci_build, :success), create(:ci_build, :running)] }
      it { is_expected.to eq 'running' }
    end

    context 'at least one pending' do
      let(:builds) { [create(:ci_build, :success), create(:ci_build, :pending)] }
      it { is_expected.to eq 'running' }
    end

    context 'build success and failed but allowed to fail' do
      let(:builds) { [create(:ci_build, :success), create(:ci_build, :failed, :allowed_to_fail)] }
      it { is_expected.to eq 'success' }
    end

    context 'one build failed but allowed to fail' do
      let(:builds) { [create(:ci_build, :failed, :allowed_to_fail)] }
      it { is_expected.to eq 'success' }
    end
  end
end
