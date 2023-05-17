# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SecretDetectionCreateService, :snowplow, feature_category: :container_scanning do
  subject(:result) { described_class.new(project, user).execute }

  let(:branch_name) { 'set-secret-detection-config-1' }

  let(:snowplow_event) do
    {
      category: 'Security::CiConfiguration::SecretDetectionCreateService',
      action: 'create',
      label: ''
    }
  end

  include_examples 'services security ci configuration create service', true
end
