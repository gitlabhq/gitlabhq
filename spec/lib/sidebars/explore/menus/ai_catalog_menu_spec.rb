# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Explore::Menus::AiCatalogMenu, feature_category: :navigation do
  let_it_be(:current_user) { build(:user) }
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: current_user, container: user) }

  subject(:menu_item) { described_class.new(context) }

  describe '#link' do
    it 'matches the expected path pattern' do
      expect(menu_item.link).to match %r{explore/ai-catalog}
    end
  end

  describe '#title' do
    it 'returns the correct title' do
      expect(menu_item.title).to eq 'AI Catalog'
    end
  end

  describe '#sprite_icon' do
    it 'returns the correct icon' do
      expect(menu_item.sprite_icon).to eq 'tanuki-ai'
    end
  end

  describe '#active_routes' do
    it 'returns the correct active routes' do
      expect(menu_item.active_routes).to eq({ controller: ['explore/ai_catalog'] })
    end
  end

  describe '#render?' do
    it 'renders the menu' do
      expect(menu_item.render?).to be(true)
    end

    context 'when global_ai_catalog feature flag is disabled' do
      before do
        stub_feature_flags(global_ai_catalog: false)
      end

      it 'does not render the menu' do
        expect(menu_item.render?).to be(false)
      end
    end
  end

  describe 'feature flag integration' do
    it 'calls Feature.enabled? with correct parameters' do
      expect(Feature).to receive(:enabled?).with(:global_ai_catalog, current_user)

      menu_item.render?
    end
  end
end
