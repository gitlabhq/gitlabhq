# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::IssuesMenu, feature_category: :navigation do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:menu) { subject }
    let(:extra_attrs) do
      {
        item_id: :project_issue_list,
        active_routes: { path: %w[projects/issues#index projects/issues#show projects/issues#new] },
        pill_count: menu.pill_count,
        pill_count_field: menu.pill_count_field,
        has_pill: menu.has_pill?,
        super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::PlanMenu
      }
    end
  end

  describe '#render?' do
    context 'when user can read issues' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end

    context 'when user cannot read issues' do
      let(:user) { nil }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end

  describe '#has_pill?' do
    context 'when issues feature is enabled' do
      it 'returns true' do
        expect(subject.has_pill?).to eq true
      end
    end

    context 'when issue feature is disabled' do
      it 'returns false' do
        allow(project).to receive(:issues_enabled?).and_return(false)

        expect(subject.has_pill?).to eq false
      end
    end
  end

  describe '#pill_count_field' do
    it 'returns the correct GraphQL field name' do
      expect(subject.pill_count_field).to eq('openIssuesCount')
    end
  end

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Service Desk' do
      let(:item_id) { :service_desk }

      describe 'when service desk is supported' do
        before do
          allow(::ServiceDesk).to receive(:supported?).and_return(true)
        end

        describe 'when service desk is enabled' do
          before do
            project.update!(service_desk_enabled: true)
          end

          it { is_expected.not_to be_nil }
        end

        describe 'when service desk is disabled' do
          before do
            project.update!(service_desk_enabled: false)
          end

          it { is_expected.to be_nil }
        end
      end

      describe 'when service desk is unsupported' do
        before do
          allow(::ServiceDesk).to receive(:supported?).and_return(false)
          project.update!(service_desk_enabled: true)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
