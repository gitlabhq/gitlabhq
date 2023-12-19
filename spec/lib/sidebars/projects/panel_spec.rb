# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Panel, feature_category: :navigation do
  let_it_be(:project) { create(:project) }

  let(:context) { Sidebars::Projects::Context.new(current_user: nil, container: project) }

  subject { described_class.new(context) }

  it 'has a scope menu' do
    expect(subject.scope_menu).to be_a(Sidebars::Projects::Menus::ScopeMenu)
  end

  context 'Confluence menu item' do
    subject { described_class.new(context).instance_variable_get(:@menus) }

    context 'when integration is present and active' do
      context 'confluence only' do
        let_it_be(:confluence) { create(:confluence_integration, active: true) }

        let(:project) { confluence.project }

        it 'contains Confluence menu item' do
          expect(subject.index { |i| i.is_a?(Sidebars::Projects::Menus::ConfluenceMenu) }).not_to be_nil
        end

        it 'does not contain Wiki menu item' do
          expect(subject.index { |i| i.is_a?(Sidebars::Projects::Menus::WikiMenu) }).to be_nil
        end
      end
    end

    context 'when integration is not present' do
      it 'does not contain Confluence menu item' do
        expect(subject.index { |i| i.is_a?(Sidebars::Projects::Menus::ConfluenceMenu) }).to be_nil
      end

      it 'contains Wiki menu item' do
        expect(subject.index { |i| i.is_a?(Sidebars::Projects::Menus::WikiMenu) }).not_to be_nil
      end
    end
  end
end
