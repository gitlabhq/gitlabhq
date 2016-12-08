require 'spec_helper'

describe Gitlab::Ci::Status::Canceled do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.label).to eq 'canceled' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'canceled' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_canceled' }
  end

  describe '#title' do
    it { expect(subject.title).to eq 'Double: canceled' }
  end
end
