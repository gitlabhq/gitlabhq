# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Status::WaitingForResource do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'waiting' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'waiting for resource' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_pending' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_pending' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'waiting-for-resource' }
  end
end
