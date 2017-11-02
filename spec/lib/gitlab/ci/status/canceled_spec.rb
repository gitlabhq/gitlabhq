require 'spec_helper'

describe Gitlab::Ci::Status::Canceled do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'canceled' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'canceled' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_canceled' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_canceled' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'canceled' }
  end
end
