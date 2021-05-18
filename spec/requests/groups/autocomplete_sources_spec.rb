# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups autocomplete' do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group, :private) }

  before_all do
    group.add_developer(user)
  end

  before do
    sign_in(user)
  end

  describe '#issues' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:incident) { create(:incident, project: project) }

    let(:none) { [] }
    let(:all) { [issue, incident] }

    where(:issue_types, :expected) do
      nil         | :all
      ''          | :all
      'invalid'   | :none
      'issue'     | :issue
      'incident'  | :incident
    end

    with_them do
      it 'returns the correct response', :aggregate_failures do
        issues = Array(expected).flat_map { |sym| public_send(sym) }

        get issues_group_autocomplete_sources_path(group, issue_types: issue_types)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(issues.size)
        expect(json_response.map { |issue| issue['iid'] })
          .to match_array(issues.map(&:iid))
      end
    end
  end

  describe '#milestones' do
    it 'returns correct response' do
      parent_group = create(:group, :private)
      group.update!(parent: parent_group)
      sub_group = create(:group, :private, parent: sub_group)
      create(:milestone, group: parent_group)
      create(:milestone, group: sub_group)
      group_milestone = create(:milestone, group: group)

      get milestones_group_autocomplete_sources_path(group)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.count).to eq(1)
      expect(json_response.first).to include(
        'iid' => group_milestone.iid, 'title' => group_milestone.title
      )
    end
  end
end
