# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::ApplicationsMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/user_settings/applications',
    title: _('Applications'),
    icon: 'applications',
    active_routes: { controller: 'oauth/applications' }

  it_behaves_like 'User settings menu #render? method'
end
