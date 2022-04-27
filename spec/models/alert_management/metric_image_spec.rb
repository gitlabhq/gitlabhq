# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::MetricImage do
  subject { build(:alert_metric_image) }

  describe 'associations' do
    it { is_expected.to belong_to(:alert) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_length_of(:url).is_at_most(255) }
    it { is_expected.to validate_length_of(:url_text).is_at_most(128) }
  end
end
