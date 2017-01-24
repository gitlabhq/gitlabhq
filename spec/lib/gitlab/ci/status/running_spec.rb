require 'spec_helper'

describe Gitlab::Ci::Status::Running do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.label).to eq 'running' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'running' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_running' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'running' }
  end
end
