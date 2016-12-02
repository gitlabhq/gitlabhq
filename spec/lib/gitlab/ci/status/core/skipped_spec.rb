require 'spec_helper'

describe Gitlab::Ci::Status::Core::Skipped do
  subject { described_class.new(double('subject')) }

  describe '#label' do
    it { expect(subject.label).to eq 'skipped' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_skipped' }
  end

  describe '#title' do
    it { expect(subject.title).to eq 'Double: skipped' }
  end
end
