# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ArtifactRegistryController, :routing, feature_category: :organization do
  let_it_be(:organization) { build(:organization) }

  specify 'to #index' do
    expect(get("/o/#{organization.path}/-/artifact_registry"))
      .to route_to('organizations/artifact_registry#index', organization_path: organization.path)
  end
end
