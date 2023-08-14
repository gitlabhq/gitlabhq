# frozen_string_literal: true

# See https://docs.gitlab.com/ee/user/profile/contributions_calendar.html#user-contribution-events
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.shared_context 'with user contribution events' do
  # targets

  # issue
  let_it_be(:issue) { create(:issue, project: project) }

  # merge requeest
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  # milestone
  let_it_be(:milestone) { create(:milestone, project: project) }

  # design
  let_it_be(:design) { create(:design, project: project, issue: issue, author: user) }

  # note
  let_it_be(:note_on_issue) { create(:note_on_issue, noteable: issue, project: project) }
  let_it_be(:note_on_merge_request) { create(:note_on_merge_request, noteable: merge_request, project: project) }
  let_it_be(:note_on_project_snippet) { create(:note_on_project_snippet, project: project) }
  let_it_be(:note_on_design) { create(:note_on_design, noteable: design) }
  let_it_be(:note_on_personal_snippet) do
    create(:note, project: nil, noteable: create(:personal_snippet, author: user))
  end

  # work item
  let_it_be(:incident) { create(:work_item, :incident, author: user, project: project) }
  let_it_be(:task) { create(:work_item, :task, author: user, project: project) }

  # events

  # approved
  let_it_be(:approved_merge_request_event) do
    create(:event, :approved, author: user, project: project, target: merge_request)
  end

  # closed
  let_it_be(:closed_issue_event) { create(:event, :closed, author: user, project: project, target: issue) }
  let_it_be(:closed_milestone_event) { create(:event, :closed, author: user, project: project, target: milestone) }
  let_it_be(:closed_merge_request_event) do
    create(:event, :closed, author: user, project: project, target: merge_request)
  end

  let_it_be(:closed_task_event) do
    create(:event, :closed, :for_work_item, author: user, project: project, target: task)
  end

  let_it_be(:closed_incident_event) do
    create(:event, :closed, :for_work_item, author: user, project: project, target: incident)
  end

  # commented
  let_it_be(:commented_issue_event) do
    create(:event, :commented, author: user, project: project, target: note_on_issue)
  end

  let_it_be(:commented_merge_request_event) do
    create(:event, :commented, author: user, project: project, target: note_on_merge_request)
  end

  let_it_be(:commented_project_snippet_event) do
    create(:event, :commented, author: user, target: note_on_project_snippet)
  end

  let_it_be(:commented_personal_snippet_event) do
    create(:event, :commented, project: nil, author: user, target: note_on_personal_snippet)
  end

  let_it_be(:commented_design_event) do
    create(:event, :commented, author: user, target: note_on_design)
  end

  # created
  let_it_be(:created_issue_event) { create(:event, :created, author: user, project: project, target: issue) }
  let_it_be(:created_milestone_event) { create(:event, :created, author: user, project: project, target: milestone) }
  let_it_be(:created_design_event) { create(:design_event, project: project, author: user) }
  let_it_be(:created_project_event) { create(:event, :created, project: project, author: user) }
  let_it_be(:created_wiki_page_event) { create(:wiki_page_event, :created, project: project, author: user) }
  let_it_be(:created_incident_event) do
    create(:event, :created, :for_work_item, author: user, project: project, target: incident)
  end

  let_it_be(:created_task_event) do
    create(:event, :created, :for_work_item, author: user, project: project, target: task)
  end

  let_it_be(:created_merge_request_event) do
    create(:event, :created, author: user, project: project, target: merge_request)
  end

  # destroyed
  let_it_be(:destroyed_design_event) { create(:event, :destroyed, project: project, author: user, target: design) }
  let_it_be(:destroyed_wiki_page_event) { create(:wiki_page_event, :destroyed, project: project, author: user) }
  let_it_be(:destroyed_milestone_event) do
    create(:event, :destroyed, author: user, project: project, target: milestone)
  end

  # expired
  let_it_be(:expired_event) { create(:event, :expired, project: project, author: user) }

  # joined
  let_it_be(:joined_event) { create(:event, :joined, project: project, author: user) }

  # left
  let_it_be(:left_event) { create(:event, :left, project: project, author: user) }

  # merged
  let_it_be(:merged_merge_request_event) do
    create(:event, :merged, author: user, project: project, target: merge_request)
  end

  # pushed
  commit_title = 'Initial commit'
  let_it_be(:push_event_branch_payload_pushed) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event, commit_title: commit_title)
    event
  end

  let_it_be(:push_event_branch_payload_created) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event, action: :created, commit_title: commit_title)
    event
  end

  let_it_be(:push_event_branch_payload_removed) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event, action: :removed)
    event
  end

  let_it_be(:push_event_tag_payload_pushed) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event, ref_type: :tag, commit_title: commit_title)
    event
  end

  let_it_be(:push_event_tag_payload_created) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event, ref_type: :tag, action: :created, commit_title: commit_title)
    event
  end

  let_it_be(:push_event_tag_payload_removed) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event, ref_type: :tag, action: :removed)
    event
  end

  let_it_be(:bulk_push_event) do
    event = create(:push_event, project: project, author: user)
    create(
      :push_event_payload,
      event: event,
      commit_count: 5,
      commit_from: '83c6aa31482b9076531ed3a880e75627fd6b335c',
      commit_title: commit_title
    )
    event
  end

  # reopened
  let_it_be(:reopened_issue_event) { create(:event, :reopened, author: user, project: project, target: issue) }
  let_it_be(:reopened_milestone_event) { create(:event, :reopened, author: user, project: project, target: milestone) }
  let_it_be(:reopened_task_event) { create(:event, :reopened, author: user, project: project, target: task) }
  let_it_be(:reopened_incident_event) { create(:event, :reopened, author: user, project: project, target: incident) }
  let_it_be(:reopened_merge_request_event) do
    create(:event, :reopened, author: user, project: project, target: merge_request)
  end

  # updated
  let_it_be(:updated_wiki_page_event) { create(:wiki_page_event, :updated, project: project, author: user) }
  let_it_be(:updated_design_event) { create(:event, :updated, project: project, author: user, target: design) }
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
