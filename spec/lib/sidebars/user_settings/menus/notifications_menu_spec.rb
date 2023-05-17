# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::NotificationsMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/notifications',
    title: _('Notifications'),
    icon: 'notifications',
    active_routes: { controller: :notifications }

  it_behaves_like 'User settings menu #render? method'
end
