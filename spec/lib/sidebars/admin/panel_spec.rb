# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Panel, feature_category: :navigation do
  let_it_be(:user) { build(:admin) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject(:panel) { described_class.new(context) }

  describe '#aria_label' do
    it 'returns the correct aria label' do
      expect(panel.aria_label).to eq(_('Admin area'))
    end
  end

  describe '#super_sidebar_context_header' do
    it 'returns a hash with the correct title and icon' do
      expect(panel.super_sidebar_context_header).to eq(_('Admin area'))
    end
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel instantiable by the anonymous user'

  describe 'system hooks disabled on GitLab.com' do
    let(:gitlab_com?) { false }

    before do
      allow(::Gitlab).to receive(:com?) { gitlab_com? }
    end

    context 'when on GitLab.com' do
      let(:gitlab_com?) { true }

      it 'does not include the SystemHooksMenu' do
        expect(panel.instance_variable_get(:@menus).map(&:class))
          .not_to include(Sidebars::Admin::Menus::SystemHooksMenu)
      end
    end

    context 'when not on GitLab.com' do
      it 'includes the SystemHooksMenu' do
        expect(panel.instance_variable_get(:@menus).map(&:class))
          .to include(Sidebars::Admin::Menus::SystemHooksMenu)
      end
    end
  end
end
