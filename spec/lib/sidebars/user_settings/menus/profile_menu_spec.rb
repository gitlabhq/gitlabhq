# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::ProfileMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile',
    title: _('Profile'),
    icon: 'profile',
    active_routes: { path: 'profiles#show' }

  it_behaves_like 'User settings menu #render? method'
end
