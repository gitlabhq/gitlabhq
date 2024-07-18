# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::MessagesMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/broadcast_messages',
    title: s_('Admin|Messages'),
    icon: 'bullhorn'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :broadcast_messages }
end
