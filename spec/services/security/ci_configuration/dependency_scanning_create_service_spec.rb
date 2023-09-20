# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::DependencyScanningCreateService, :snowplow,
  feature_category: :software_composition_analysis do
  subject(:result) { described_class.new(project, user).execute }

  let(:branch_name) { 'set-dependency-scanning-config-1' }

  let(:snowplow_event) do
    {
      category: 'Security::CiConfiguration::DependencyScanningCreateService',
      action: 'create',
      label: ''
    }
  end

  include_examples 'services security ci configuration create service', true
end
