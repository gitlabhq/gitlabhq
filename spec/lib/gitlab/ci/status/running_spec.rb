require 'spec_helper'

describe Gitlab::Ci::Status::Running do
  subject { described_class.new(double('subject')) }

  describe '#text' do
    it { expect(subject.label).to eq 'running' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'running' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_running' }
  end

  describe '#title' do
    it { expect(subject.title).to eq 'Double: running' }
  end
end
