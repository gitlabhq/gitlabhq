# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ProjectInformationMenu, feature_category: :navigation do
  let_it_be_with_reload(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  it_behaves_like 'not serializable as super_sidebar_menu_args' do
    let(:menu) { described_class.new(context) }
  end

  describe '#container_html_options' do
    subject { described_class.new(context).container_html_options }

    it { is_expected.to match(hash_including(class: 'shortcuts-project-information has-sub-items')) }
  end

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Labels' do
      let(:item_id) { :labels }

      it { is_expected.not_to be_nil }

      context 'when merge requests are disabled' do
        before do
          project.project_feature.update_attribute(:merge_requests_access_level, Featurable::DISABLED)
        end

        it { is_expected.not_to be_nil }
      end

      context 'when issues are disabled' do
        before do
          project.project_feature.update_attribute(:issues_access_level, Featurable::DISABLED)
        end

        it { is_expected.not_to be_nil }
      end

      context 'when merge requests and issues are disabled' do
        before do
          project.project_feature.update_attribute(:merge_requests_access_level, Featurable::DISABLED)
          project.project_feature.update_attribute(:issues_access_level, Featurable::DISABLED)
        end

        it { is_expected.to be_nil }
      end
    end

    describe 'Members' do
      let(:item_id) { :members }

      it { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end
  end
end
