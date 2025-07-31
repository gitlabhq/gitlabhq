# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::SshKeysMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/user_settings/ssh_keys',
    title: _('SSH Keys'),
    icon: 'key',
    active_routes: { controller: :ssh_keys }

  it_behaves_like 'User settings menu #render? method'
end
