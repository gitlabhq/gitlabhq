# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::AuthenticationLogMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/audit_log',
    title: _('Authentication Log'),
    icon: 'log',
    active_routes: { path: 'profiles#audit_log' }

  it_behaves_like 'User settings menu #render? method'
end
