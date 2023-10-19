# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::SettingsController, :routing, feature_category: :cell do
  let_it_be(:organization) { build(:organization) }

  it 'routes to settings#general' do
    expect(get("/-/organizations/#{organization.path}/settings/general"))
      .to route_to('organizations/settings#general', organization_path: organization.path)
  end
end
