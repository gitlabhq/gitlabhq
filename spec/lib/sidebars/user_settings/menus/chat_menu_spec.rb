# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::ChatMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/chat',
    title: _('Chat'),
    icon: 'comment',
    active_routes: { controller: :chat_names }

  it_behaves_like 'User settings menu #render? method'
end
