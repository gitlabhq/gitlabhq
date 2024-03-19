# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Canceled, feature_category: :continuous_integration do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'Canceled' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'canceled' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_canceled' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_canceled' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'canceled' }
  end

  describe '#details_path' do
    it { expect(subject.details_path).to be_nil }
  end
end
