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

  describe '#uploads_sharding_key' do
    it 'returns project_id' do
      project = build_stubbed(:project)
      metric_image = build_stubbed(:alert_metric_image, project_id: project.id)

      expect(metric_image.uploads_sharding_key).to eq(project_id: project.id)
    end
  end
end
