# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Scheduled, feature_category: :continuous_integration do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'Scheduled' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'scheduled' }
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

  describe '#details_path' do
    it { expect(subject.details_path).to be_nil }
  end
end
