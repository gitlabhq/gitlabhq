# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::AuthenticationLogMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/user_settings/authentication_log',
    title: _('Authentication Log'),
    icon: 'log',
    active_routes: { path: 'user_settings#authentication_log' }

  it_behaves_like 'User settings menu #render? method'
end
