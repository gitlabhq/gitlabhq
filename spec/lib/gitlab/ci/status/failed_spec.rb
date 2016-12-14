require 'spec_helper'

describe Gitlab::Ci::Status::Failed do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.label).to eq 'failed' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'failed' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_failed' }
  end
end
