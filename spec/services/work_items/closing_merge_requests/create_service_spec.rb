# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ClosingMergeRequests::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:project) { create(:project, :repository, :private, group: group) }
    let_it_be(:developer) { create(:user, developer_of: group) }
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:private_merge_request) do
      create(:merge_request, source_project: create(:project, :repository, :private))
    end

    let(:current_user) { developer }
    let(:mr_reference) { merge_request.to_reference }
    let(:namespace_path) { project.full_path }

    subject(:create_result) do
      described_class.new(
        current_user: current_user,
        work_item: work_item,
        merge_request_reference: mr_reference,
        namespace_path: namespace_path
      ).execute
    end

    context 'when work item belongs to a project' do
      let_it_be_with_refind(:work_item) { create(:work_item, project: project) }

      it_behaves_like 'a service that adds closing merge requests'
    end
  end
end
