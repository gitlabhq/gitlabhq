# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::AccessMenu, feature_category: :navigation do
  let(:user) { build_stubbed(:user, :admin) }
  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }
  let(:menu) { described_class.new(context) }

  before do
    # Credentials is inserted first in EE; hide it so the menu link resolves to Deploy keys here.
    stub_licensed_features(credentials_inventory: false) if Gitlab.ee?
  end

  it_behaves_like 'Admin menu',
    link: '/admin/deploy_keys',
    title: s_('Admin|Access'),
    icon: 'shield'

  it_behaves_like 'Admin menu with sub menus'

  it_behaves_like 'Admin menu with extra container html options',
    extra_container_html_options: { testid: 'admin-access-menu-link' }

  describe 'Menu items', :enable_admin_mode do
    subject(:item) { menu.renderable_items.find { |e| e.item_id == item_id } }

    describe 'Deploy keys' do
      let(:item_id) { :deploy_keys }

      it 'is rendered with the deploy keys link' do
        expect(item.title).to eq(s_('Admin|Deploy keys'))
        expect(item.link).to eq('/admin/deploy_keys')
        expect(item.active_routes).to eq(controller: :deploy_keys)
      end
    end

    describe 'Certificate authorities' do
      let(:item_id) { :ssh_certificates }

      before do
        allow(InstanceSshCertificate).to receive(:available?).and_return(available)
      end

      context 'when instance SSH certificates are available' do
        let(:available) { true }

        it 'is rendered after deploy keys with the certificate authorities link' do
          expect(menu.renderable_items.map(&:item_id)).to eq([:deploy_keys, :ssh_certificates])
          expect(item.title).to eq(s_('SshCertificates|Certificate authorities'))
          expect(item.link).to eq('/admin/ssh_certificates')
          expect(item.active_routes).to eq(controller: :ssh_certificates)
        end
      end

      context 'when instance SSH certificates are unavailable' do
        let(:available) { false }

        it { is_expected.to be_nil }

        it 'still renders the menu with deploy keys' do
          expect(menu.render?).to be(true)
          expect(menu.renderable_items.map(&:item_id)).to eq([:deploy_keys])
        end
      end
    end
  end
end
