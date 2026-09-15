# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Organizations::SettingsController, :routing, feature_category: :organization do
  let_it_be(:organization) { build(:organization) }

  specify 'to settings#general' do
    expect(get("/o/#{organization.path}/admin/settings/general"))
      .to route_to('admin/organizations/settings#general', organization_path: organization.path)
  end
end
