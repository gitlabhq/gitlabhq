# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::Description, feature_category: :team_planning do
  let(:user) { build(:user) }
  let(:last_edited_at) { Time.zone.parse('2024-12-01 10:30:00 UTC') }
  let(:task_completion_status) { { count: 3, completed_count: 1 } }

  let(:work_item) do
    build(
      :work_item,
      description: 'Refine keyboard shortcut mappings',
      last_edited_at: last_edited_at,
      last_edited_by: user
    ).tap do |item|
      allow(item).to receive(:task_completion_status).and_return(task_completion_status)
    end
  end

  let(:widget) { WorkItems::Widgets::Description.new(work_item) }

  subject(:representation) do
    described_class.new(widget).as_json
  end

  describe 'description_html', feature_category: :team_planning do
    let(:current_user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project_a) { create(:project, :public, group: group, name: 'a', path: 'a') }
    let_it_be(:project_b) { create(:project, :public, group: group, name: 'b', path: 'b') }
    let_it_be(:issue) { create(:issue, :confidential, project: project_b) }

    let(:work_item) do
      create(:work_item, project: project_a, description: "Work item references #{issue.to_reference(project_a)}")
    end

    let(:widget) { WorkItems::Widgets::Description.new(work_item) }
    let(:entity) { described_class.new(widget, current_user: current_user) }
    let(:issue_path) { Gitlab::UrlBuilder.build(issue, only_path: true) }
    let(:issue_title) { issue.title }

    subject(:description_html) { entity.as_json[:description_html] }

    it 'renders references if current user has access to the referent' do
      project_b.add_reporter(current_user)

      expect(description_html).to include(issue_path)
      expect(description_html).to include(issue_title)
    end

    it 'redacts references if current user has no access to the referent' do
      project_a.add_guest(current_user)

      expect(description_html).not_to include(issue_path)
      expect(description_html).not_to include(issue_title)
    end
  end

  it 'exposes the description feature payload' do
    aggregate_failures do
      expect(representation[:description]).to eq('Refine keyboard shortcut mappings')
      expect(representation[:description_html]).to include('Refine keyboard shortcut mappings')

      expect(representation).to include(edited: true)
      expect(representation[:last_edited_at]).to eq(last_edited_at)

      expected_editor = API::Entities::UserBasic
        .new(user)
        .as_json

      expect(representation[:last_edited_by]).to eq(expected_editor)
      expect(representation[:task_completion_status]).to eq(task_completion_status)
    end
  end
end
