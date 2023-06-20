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

  # note
  let_it_be(:note_on_issue) { create(:note_on_issue, noteable: issue, project: project) }

  # design
  let_it_be(:design) { create(:design, project: project, issue: issue, author: user) }

  # work item
  let_it_be(:incident) { create(:work_item, :incident, author: user, project: project) }
  let_it_be(:test_case)  { create(:work_item, :test_case, author: user, project: project) }
  let_it_be(:requirement) { create(:work_item, :requirement, author: user, project: project) }
  let_it_be(:task) { create(:work_item, :task, author: user, project: project) }

  # events

  # approved
  let_it_be(:approved_merge_request_event) do
    create(:event, :approved, author: user, project: project, target: merge_request)
  end

  # closed
  let_it_be(:closed_issue_event) { create(:event, :closed, author: user, project: project, target: issue) }
  let_it_be(:closed_milestone_event) { create(:event, :closed, author: user, project: project, target: milestone) }
  let_it_be(:closed_incident_event) { create(:event, :closed, author: user, project: project, target: incident) }
  let_it_be(:closed_test_case_event) { create(:event, :closed, author: user, project: project, target: test_case) }
  let_it_be(:closed_merge_request_event) do
    create(:event, :closed, author: user, project: project, target: merge_request)
  end

  # commented
  let_it_be(:commented_event) do
    create(:event, :commented, author: user, project: project, target: note_on_issue)
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

  let_it_be(:created_test_case_event) do
    create(:event, :created, :for_work_item, author: user, project: project, target: test_case)
  end

  let_it_be(:created_requirement_event) do
    create(:event, :created, :for_work_item, author: user, project: project, target: requirement)
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
  let_it_be(:push_event_payload_pushed) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event)
    event
  end

  let_it_be(:push_event_payload_created) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event, action: :created)
    event
  end

  let_it_be(:push_event_payload_removed) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event, action: :removed)
    event
  end

  let_it_be(:bulk_push_event) do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload, event: event, commit_count: 5, commit_from: '83c6aa31482b9076531ed3a880e75627fd6b335c')
    event
  end

  # reopened
  let_it_be(:reopened_issue_event) { create(:event, :reopened, author: user, project: project, target: issue) }
  let_it_be(:reopened_milestone_event) { create(:event, :reopened, author: user, project: project, target: milestone) }
  let_it_be(:reopened_incident_event) { create(:event, :reopened, author: user, project: project, target: incident) }
  let_it_be(:reopened_test_case_event) { create(:event, :reopened, author: user, project: project, target: test_case) }
  let_it_be(:reopened_merge_request_event) do
    create(:event, :reopened, author: user, project: project, target: merge_request)
  end

  # updated
  let_it_be(:updated_wiki_page_event) { create(:wiki_page_event, :updated, project: project, author: user) }
  let_it_be(:updated_design_event) { create(:event, :updated, project: project, author: user, target: design) }
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
