require 'spec_helper'

describe Gitlab::Ci::Status::Created do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.label).to eq 'created' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'created' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_created' }
  end
end
