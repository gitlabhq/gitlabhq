# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Pending do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'Pending' }
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

  describe '#group' do
    it { expect(subject.group).to eq 'pending' }
  end

  describe '#details_path' do
    it { expect(subject.details_path).to be_nil }
  end
end
