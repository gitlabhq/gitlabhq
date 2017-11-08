require 'spec_helper'

describe Gitlab::Ci::Status::Created do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'created' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'created' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_created' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_created' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'created' }
  end
end
