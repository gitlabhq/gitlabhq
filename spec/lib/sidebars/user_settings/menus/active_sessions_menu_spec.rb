# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::ActiveSessionsMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/user_settings/active_sessions',
    title: _('Active Sessions'),
    icon: 'monitor-lines',
    active_routes: { controller: :active_sessions }

  it_behaves_like 'User settings menu #render? method'
end
