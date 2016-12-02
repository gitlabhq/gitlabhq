require 'spec_helper'

describe Gitlab::Ci::Status::Core::Created do
  subject { described_class.new(double('subject')) }

  describe '#label' do
    it { expect(subject.label).to eq 'created' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_created' }
  end

  describe '#title' do
    it { expect(subject.title).to eq 'Double: created' }
  end
end
