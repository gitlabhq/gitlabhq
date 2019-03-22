# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Status::Preparing do
  subject do
    described_class.new(double('subject'), nil)
  end

  describe '#text' do
    it { expect(subject.text).to eq 'preparing' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'preparing' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_created' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_created' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'preparing' }
  end
end
