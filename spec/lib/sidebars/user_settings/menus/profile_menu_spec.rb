# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::ProfileMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/user_settings/profile',
    title: _('Profile'),
    icon: 'profile',
    active_routes: { path: 'user_settings/profiles#show' }

  it_behaves_like 'User settings menu #render? method'
end
