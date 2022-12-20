# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::DiscussionsListService do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :repository, :private, group: group) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:label) { create(:label, project: project) }

  let(:finder_params_for_issuable) { {} }

  subject(:discussions_service) { described_class.new(current_user, issuable, finder_params_for_issuable) }

  describe 'fetching notes for issue' do
    let_it_be(:issuable) { create(:issue, project: project) }

    it_behaves_like 'listing issuable discussions', :guest, 1, 7

    context 'without notes widget' do
      let_it_be(:issuable) { create(:work_item, :issue, project: project) }

      before do
        stub_const('WorkItems::Type::BASE_TYPES', { issue: { name: 'NoNotesWidget', enum_value: 0 } })
        stub_const('WorkItems::Type::WIDGETS_FOR_TYPE', { issue: [::WorkItems::Widgets::Description] })
      end

      it "returns no notes" do
        expect(discussions_service.execute).to be_empty
      end
    end
  end

  describe 'fetching notes for merge requests' do
    let_it_be(:issuable) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like 'listing issuable discussions', :reporter, 0, 6
  end
end
