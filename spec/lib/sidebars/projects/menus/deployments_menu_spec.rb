# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::DeploymentsMenu do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

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
      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Feature Flags' do
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
  end
end
