# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::AnalyticsMenu do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: project.repository.root_ref) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'whe user cannot read analytics' do
      let(:user) { nil }

      it 'returns false' do
        expect(subject.render?).to be false
      end
    end

    context 'whe user can read analytics' do
      it 'returns true' do
        expect(subject.render?).to be true
      end

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
  end

  describe '#link' do
    it 'returns link to the value stream page' do
      expect(subject.link).to include('/-/value_stream_analytics')
    end

    context 'when Value Stream is not visible' do
      it 'returns link to the the first visible menu item' do
        allow(subject).to receive(:cycle_analytics_menu_item).and_return(double(render?: false))

        expect(subject.link).to eq subject.renderable_items.first.link
      end
    end
  end

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'CI/CD' do
      let(:item_id) { :ci_cd_analytics }

      specify { is_expected.not_to be_nil }

      describe 'when the project repository is empty' do
        before do
          allow(project).to receive(:empty_repo?).and_return(true)
        end

        specify { is_expected.to be_nil }
      end

      describe 'when builds access level is DISABLED' do
        before do
          project.project_feature.update!(builds_access_level: Featurable::DISABLED)
        end

        specify { is_expected.to be_nil }
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Repository' do
      let(:item_id) { :repository_analytics }

      specify { is_expected.not_to be_nil }

      describe 'when the project repository is empty' do
        before do
          allow(project).to receive(:empty_repo?).and_return(true)
        end

        specify { is_expected.to be_nil }
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Value Stream' do
      let(:item_id) { :cycle_analytics }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end
  end
end
