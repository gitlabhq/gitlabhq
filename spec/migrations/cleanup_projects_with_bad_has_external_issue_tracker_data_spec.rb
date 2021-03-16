# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe CleanupProjectsWithBadHasExternalIssueTrackerData, :migration do
  let(:namespace) { table(:namespaces).create!(name: 'foo', path: 'bar') }
  let(:projects) { table(:projects) }
  let(:services) { table(:services) }

  def create_projects!(num)
    Array.new(num) do
      projects.create!(namespace_id: namespace.id)
    end
  end

  def create_active_external_issue_tracker_integrations!(*projects)
    projects.each do |project|
      services.create!(category: 'issue_tracker', project_id: project.id, active: true)
    end
  end

  def create_disabled_external_issue_tracker_integrations!(*projects)
    projects.each do |project|
      services.create!(category: 'issue_tracker', project_id: project.id, active: false)
    end
  end

  def create_active_other_integrations!(*projects)
    projects.each do |project|
      services.create!(category: 'not_an_issue_tracker', project_id: project.id, active: true)
    end
  end

  it 'sets `projects.has_external_issue_tracker` correctly' do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)

    project_with_an_external_issue_tracker_1,
      project_with_an_external_issue_tracker_2,
      project_with_only_a_disabled_external_issue_tracker_1,
      project_with_only_a_disabled_external_issue_tracker_2,
      project_without_any_external_issue_trackers_1,
      project_without_any_external_issue_trackers_2 = create_projects!(6)

    create_active_external_issue_tracker_integrations!(
      project_with_an_external_issue_tracker_1,
      project_with_an_external_issue_tracker_2
    )

    create_disabled_external_issue_tracker_integrations!(
      project_with_an_external_issue_tracker_1,
      project_with_an_external_issue_tracker_2,
      project_with_only_a_disabled_external_issue_tracker_1,
      project_with_only_a_disabled_external_issue_tracker_2
    )

    create_active_other_integrations!(
      project_with_an_external_issue_tracker_1,
      project_with_an_external_issue_tracker_2,
      project_without_any_external_issue_trackers_1,
      project_without_any_external_issue_trackers_2
    )

    # PG triggers on the services table added in
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51852 will have set
    # the `has_external_issue_tracker` columns to correct data when the services
    # records were created above.
    #
    # We set the `has_external_issue_tracker` columns for projects to incorrect
    # data manually below to emulate projects in a state before the PG
    # triggers were added.
    project_with_an_external_issue_tracker_2.update!(has_external_issue_tracker: false)
    project_with_only_a_disabled_external_issue_tracker_2.update!(has_external_issue_tracker: true)
    project_without_any_external_issue_trackers_2.update!(has_external_issue_tracker: true)

    migrate!

    expected_true = [
      project_with_an_external_issue_tracker_1,
      project_with_an_external_issue_tracker_2
    ].each(&:reload).map(&:has_external_issue_tracker)

    expected_not_true = [
      project_without_any_external_issue_trackers_1,
      project_without_any_external_issue_trackers_2,
      project_with_only_a_disabled_external_issue_tracker_1,
      project_with_only_a_disabled_external_issue_tracker_2
    ].each(&:reload).map(&:has_external_issue_tracker)

    expect(expected_true).to all(eq(true))
    expect(expected_not_true).to all(be_falsey)
  end
end
