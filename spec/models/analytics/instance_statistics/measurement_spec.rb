# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::InstanceStatistics::Measurement, type: :model do
  describe 'validation' do
    let!(:measurement) { create(:instance_statistics_measurement) }

    it { is_expected.to validate_presence_of(:recorded_at) }
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_presence_of(:count) }
    it { is_expected.to validate_uniqueness_of(:recorded_at).scoped_to(:identifier) }
  end
end
