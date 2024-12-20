# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabelNote, feature_category: :team_planning do
  include Gitlab::Routing.url_helpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:label) { create(:label, project: project, title: 'label-1') }
  let_it_be(:label2) { create(:label, project: project, title: 'label-2') }

  let(:resource_parent) { project }

  context 'when resource is issue' do
    let_it_be(:resource) { create(:issue, project: project) }

    it_behaves_like 'label note created from events'

    it 'includes a link to the list of issues filtered by the label' do
      note = described_class.from_events(
        [
          create(:resource_label_event, label: label, issue: resource)
        ])

      expect(note.note_html).to include(project_issues_path(project, label_name: label.title))
    end
  end

  context 'when resource is merge request' do
    let_it_be(:resource) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like 'label note created from events'

    it 'includes a link to the list of merge requests filtered by the label' do
      note = described_class.from_events(
        [
          create(:resource_label_event, label: label, merge_request: resource)
        ])

      expect(note.note_html).to include(project_merge_requests_path(project, label_name: label.title))
    end
  end
end
