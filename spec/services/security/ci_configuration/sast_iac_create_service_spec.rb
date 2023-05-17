# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SastIacCreateService, :snowplow, feature_category: :static_application_security_testing do
  subject(:result) { described_class.new(project, user).execute }

  let(:branch_name) { 'set-sast-iac-config-1' }

  let(:snowplow_event) do
    {
      category: 'Security::CiConfiguration::SastIacCreateService',
      action: 'create',
      label: ''
    }
  end

  include_examples 'services security ci configuration create service', true
end
