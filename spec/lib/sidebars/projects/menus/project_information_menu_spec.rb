# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ProjectInformationMenu do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Releases' do
      let(:item_id) { :releases }

      specify { is_expected.to be_nil }

      context 'when feature flag :sidebar_refactor is disabled' do
        before do
          stub_feature_flags(sidebar_refactor: false)
        end

        context 'when project repository is empty' do
          it 'does not include releases menu item' do
            allow(project).to receive(:empty_repo?).and_return(true)

            is_expected.to be_nil
          end
        end

        context 'when project repository is not empty' do
          context 'when user can download code' do
            specify { is_expected.not_to be_nil }
          end

          context 'when user cannot download code' do
            let(:user) { nil }

            specify { is_expected.to be_nil }
          end
        end
      end
    end

    describe 'Labels' do
      let(:item_id) { :labels }

      specify { is_expected.not_to be_nil }

      context 'when feature flag :sidebar_refactor is disabled' do
        before do
          stub_feature_flags(sidebar_refactor: false)
        end

        specify { is_expected.to be_nil }
      end
    end

    describe 'Members' do
      let(:item_id) { :members }

      specify { is_expected.not_to be_nil }

      context 'when feature flag :sidebar_refactor is disabled' do
        before do
          stub_feature_flags(sidebar_refactor: false)
        end

        specify { is_expected.to be_nil }
      end
    end
  end
end
