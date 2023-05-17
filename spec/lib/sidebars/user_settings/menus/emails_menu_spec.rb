# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::EmailsMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/emails',
    title: _('Emails'),
    icon: 'mail',
    active_routes: { controller: :emails }

  it_behaves_like 'User settings menu #render? method'
end
