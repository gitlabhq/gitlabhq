# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::AccountMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/account',
    title: _('Account'),
    icon: 'account',
    active_routes: { controller: [:accounts, :two_factor_auths] }

  it_behaves_like 'User settings menu #render? method'
end
