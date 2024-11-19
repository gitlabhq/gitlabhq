# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::DiscussionsListService, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :repository, :private, group: group) }
  let_it_be(:milestone) { create(:milestone, group: group) }
  let_it_be(:label) { create(:group_label, group: group) }
  let_it_be(:label_2) { create(:group_label, group: group) }

  let(:finder_params_for_issuable) { {} }

  subject(:discussions_service) { described_class.new(current_user, issuable, finder_params_for_issuable) }

  describe 'fetching notes for issue' do
    let_it_be(:issuable) { create(:issue, project: project) }

    context 'when qurantined shared example', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446157' do
      it_behaves_like 'listing issuable discussions', user_role: :guest, internal_discussions: 1, total_discussions: 7
    end

    context 'without notes widget' do
      let_it_be(:issuable) { create(:work_item, project: project) }

      before do
        WorkItems::Type.default_by_type(:issue).widget_definitions.find_by_widget_type(:notes).update!(disabled: true)
      end

      it "returns no notes" do
        expect(discussions_service.execute).to be_empty
      end
    end
  end

  describe 'fetching notes for merge requests' do
    let_it_be(:issuable) { create(:merge_request, source_project: project, target_project: project) }

    context 'when qurantined shared example', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446156' do
      it_behaves_like 'listing issuable discussions',
        user_role: :reporter, internal_discussions: 0, total_discussions: 6
    end
  end
end
