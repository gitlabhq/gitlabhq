# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::DeploymentsMenu, feature_category: :navigation do
  let_it_be(:project, reload: true) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  it_behaves_like 'not serializable as super_sidebar_menu_args' do
    let(:menu) { described_class.new(context) }
  end

  describe '#render?' do
    subject { described_class.new(context) }

    context 'when menu does not have any menu items' do
      it 'returns false' do
        allow(subject).to receive(:has_renderable_items?).and_return(false)

        expect(subject.render?).to be false
      end
    end

    context 'when menu has menu items' do
      it 'returns true' do
        expect(subject.render?).to be true
      end
    end
  end

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    shared_examples 'access rights checks' do
      it { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end

      describe 'when the feature is disabled' do
        before do
          project.update_attribute("#{item_id}_access_level", 'disabled')
        end

        it { is_expected.to be_nil }
      end
    end

    describe 'Feature flags' do
      let(:item_id) { :feature_flags }

      it_behaves_like 'access rights checks'
    end

    describe 'Environments' do
      let(:item_id) { :environments }

      it_behaves_like 'access rights checks'
    end

    describe 'Releases' do
      let(:item_id) { :releases }

      it_behaves_like 'access rights checks'
    end

    describe 'Pages' do
      let(:item_id) { :pages }

      before do
        allow(::Gitlab::Pages).to receive(:enabled?).and_return(pages_enabled)
      end

      describe 'when pages are enabled' do
        let(:pages_enabled) { true }

        it { is_expected.not_to be_nil }

        describe 'when the user does not have access' do
          let(:user) { nil }

          it { is_expected.to be_nil }
        end

        it_behaves_like 'access rights checks'
      end

      describe 'when pages are not enabled' do
        let(:pages_enabled) { false }

        it { is_expected.to be_nil }
      end
    end
  end
end
