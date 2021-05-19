# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SastCreateService, :snowplow do
  subject(:result) { described_class.new(project, user, params).execute }

  let(:branch_name) { 'set-sast-config-1' }

  let(:non_empty_params) do
    { 'stage' => 'security',
      'SEARCH_MAX_DEPTH' => 1,
      'SECURE_ANALYZERS_PREFIX' => 'new_registry',
      'SAST_EXCLUDED_PATHS' => 'spec,docs' }
  end

  let(:snowplow_event) do
    {
      category: 'Security::CiConfiguration::SastCreateService',
      action: 'create',
      label: 'false'
    }
  end

  include_examples 'services security ci configuration create service'
end
