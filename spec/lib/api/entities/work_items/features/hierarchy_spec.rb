# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::Hierarchy, feature_category: :portfolio_management do
  it_behaves_like 'work item widget entity parity', described_class, Types::WorkItems::Widgets::HierarchyType,
    exceptions: %w[ancestors children has_children rolled_up_counts_by_type depth_limit_reached_by_type]

  describe '#as_json' do
    let_it_be(:reader) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:private_project) { create(:project, :private) }

    let(:widget) { WorkItems::Widgets::Hierarchy.new(work_item.reload) }

    subject(:representation) { described_class.new(widget, current_user: reader).as_json }

    context 'when the work item has no parent' do
      let_it_be(:work_item) { create(:work_item, :task, project: project) }

      it 'exposes parent as nil and has_parent as false' do
        expect(representation).to include(parent: nil, has_parent: false)
      end
    end

    context 'when the work item has a parent the user can read' do
      let_it_be(:work_item) { create(:work_item, :task, project: project) }
      let_it_be(:parent_with_access) { create(:work_item, :issue, project: project) }

      before_all do
        create(:parent_link, work_item: work_item, work_item_parent: parent_with_access)
      end

      it 'exposes the parent reference and has_parent as true' do
        expect(representation[:parent]).to include(id: parent_with_access.id, iid: parent_with_access.iid)
        expect(representation[:has_parent]).to be(true)
      end
    end

    context 'when the work item has a parent the user cannot read' do
      let_it_be(:work_item) { create(:work_item, :task, project: project) }
      let_it_be(:hidden_parent) { create(:work_item, :issue, project: private_project) }

      before_all do
        create(:parent_link, work_item: work_item, work_item_parent: hidden_parent)
      end

      it 'omits the parent details and reports has_parent as true' do
        expect(representation[:parent]).to be_nil
        expect(representation[:has_parent]).to be(true)
      end
    end
  end
end
