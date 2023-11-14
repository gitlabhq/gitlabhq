# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Explore::Menus::CatalogMenu, feature_category: :navigation do
  let_it_be(:current_user) { build(:user) }
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: current_user, container: user) }

  subject { described_class.new(context) }

  context 'when `global_ci_catalog` is enabled`' do
    it 'renders' do
      expect(subject.render?).to be(true)
    end

    it 'renders the correct link' do
      expect(subject.link).to match "explore/catalog"
    end

    it 'renders the correct title' do
      expect(subject.title).to eq "CI/CD Catalog"
    end

    it 'renders the correct icon' do
      expect(subject.sprite_icon).to eq "catalog-checkmark"
    end
  end

  context 'when `global_ci_catalog` FF is disabled' do
    before do
      stub_feature_flags(global_ci_catalog: false)
    end

    it 'does not render' do
      expect(subject.render?).to be(false)
    end
  end
end
