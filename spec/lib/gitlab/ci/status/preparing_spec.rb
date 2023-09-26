# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Preparing do
  subject do
    described_class.new(double('subject'), nil)
  end

  describe '#text' do
    it { expect(subject.text).to eq 'Preparing' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'preparing' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_preparing' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_preparing' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'preparing' }
  end

  describe '#details_path' do
    it { expect(subject.details_path).to be_nil }
  end
end
