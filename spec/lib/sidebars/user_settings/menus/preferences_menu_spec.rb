# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::PreferencesMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/preferences',
    title: _('Preferences'),
    icon: 'preferences',
    active_routes: { controller: :preferences }

  it_behaves_like 'User settings menu #render? method'
end
