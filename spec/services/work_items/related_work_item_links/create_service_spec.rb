# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::RelatedWorkItemLinks::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issuable) { create(:work_item, project: project) }
    let_it_be(:issuable2) { create(:work_item, project: project) }
    let_it_be(:restricted_issuable) { create(:work_item) }
    let_it_be(:another_project) { create(:project, group: group) }
    let_it_be(:issuable3) { create(:work_item, project: another_project) }
    let_it_be(:issuable_a) { create(:work_item, project: project) }
    let_it_be(:issuable_b) { create(:work_item, project: project) }
    let_it_be(:issuable_link) { create(:work_item_link, source: issuable, target: issuable_b) }

    let(:issuable_parent) { issuable.project }
    let(:issuable_type) { 'work item' }
    let(:issuable_link_class) { WorkItems::RelatedWorkItemLink }
    let(:params) { {} }

    before_all do
      project.add_guest(user)
      another_project.add_guest(user)
    end

    it_behaves_like 'issuable link creation', use_references: false do
      let(:response_keys) { [:status, :created_references, :message] }
      let(:async_notes) { true }
      let(:already_assigned_error_msg) { "Items are already linked" }
      let(:no_found_error_msg) do
        'No matching work item found. Make sure you are adding a valid ID and you have access to the item.'
      end
    end
  end
end
