require 'spec_helper'

describe Gitlab::Ci::Status::Pending do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'pending' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'pending' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_pending' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_pending' }
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title, :content) }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'pending' }
  end
end
