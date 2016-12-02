require 'spec_helper'

describe Gitlab::Ci::Status::Core::Success do
  subject { described_class.new(double('subject')) }

  describe '#label' do
    it { expect(subject.label).to eq 'passed' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'success' }
  end
end
