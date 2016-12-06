require 'spec_helper'

describe Gitlab::Ci::Status::Pending do
  subject { described_class.new(double('subject')) }

  describe '#text' do
    it { expect(subject.label).to eq 'pending' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'pending' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_pending' }
  end

  describe '#title' do
    it { expect(subject.title).to eq 'Double: pending' }
  end
end
