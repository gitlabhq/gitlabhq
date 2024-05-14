# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Canceling, feature_category: :continuous_integration do
  subject(:status) do
    described_class.new(double, double)
  end

  describe '#text' do
    it { expect(status.text).to eq 'Canceling' }
  end

  describe '#label' do
    it { expect(status.label).to eq 'canceling' }
  end

  describe '#icon' do
    it { expect(status.icon).to eq 'status_canceled' }
  end

  describe '#favicon' do
    it { expect(status.favicon).to eq 'favicon_status_canceled' }
  end

  describe '#group' do
    it { expect(status.group).to eq 'canceling' }
  end

  describe '#details_path' do
    it { expect(status.details_path).to be_nil }
  end
end
