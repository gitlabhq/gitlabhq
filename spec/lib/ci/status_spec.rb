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
  end
end
