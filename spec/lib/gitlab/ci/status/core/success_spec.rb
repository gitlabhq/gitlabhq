require 'spec_helper'

describe Gitlab::Ci::Status::Core::Success do
  subject { described_class.new(double('subject')) }

  describe '#text' do
    it { expect(subject.label).to eq 'passed' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'passed' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_success' }
  end

  describe '#title' do
    it { expect(subject.title).to eq 'Double: passed' }
  end
end
