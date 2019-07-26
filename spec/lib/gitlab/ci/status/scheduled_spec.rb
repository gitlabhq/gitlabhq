# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Status::Scheduled do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'delayed' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'delayed' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_scheduled' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_scheduled' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'scheduled' }
  end
end
