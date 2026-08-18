# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MetricImageUploader, feature_category: :incident_management do
  describe '.workhorse_local_upload_path' do
    it 'returns path that includes uploads dir' do
      expect(described_class.workhorse_local_upload_path).to end_with('/uploads/tmp/uploads')
    end
  end
end
