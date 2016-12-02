require 'spec_helper'

describe Gitlab::Ci::Status::Core::Failed do
  subject { described_class.new(double('subject')) }

  describe '#text' do
    it { expect(subject.label).to eq 'failed' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'failed' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_failed' }
  end

  describe '#title' do
    it { expect(subject.title).to eq 'Double: failed' }
  end
end
