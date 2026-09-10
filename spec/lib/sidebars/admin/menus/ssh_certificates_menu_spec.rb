# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::SshCertificatesMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/ssh_certificates',
    title: _('SSH certificate authorities'),
    icon: 'key'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :ssh_certificates }
end
