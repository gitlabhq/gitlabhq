# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::GpgKeysMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/user_settings/gpg_keys',
    title: _('GPG Keys'),
    icon: 'key',
    active_routes: { controller: :gpg_keys }

  it_behaves_like 'User settings menu #render? method'
end
