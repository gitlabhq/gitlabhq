# frozen_string_literal: true

require_relative './listbox_helpers'

module CycleAnalyticsHelpers
  include ::ListboxHelpers

  def toggle_value_stream_dropdown
    page.find('[data-testid="dropdown-value-streams"]').click
  end

  def path_nav_stage_names_without_median
    # Returns the path names with the median value stripped out
    page.all('.gl-path-button').collect(&:text).map { |name_with_median| name_with_median.split("\n")[0] }
  end

  def fill_in_custom_stage_fields(stage_name = nil)
    index = page.all('[data-testid="value-stream-stage-fields"]').length
    last_stage = page.all('[data-testid="value-stream-stage-fields"]').last

    stage_name = "Cool custom stage - name #{index}" if stage_name.blank?

    within last_stage do
      find('[name*="custom-stage-name-"]').fill_in with: stage_name
      select_dropdown_option_by_value "custom-stage-start-event-", 'Merge request created'
      select_dropdown_option_by_value "custom-stage-end-event-", 'Merge request merged'
    end
  end

  def select_event_label(sel)
    page.within(sel) do
      find('[data-testid="base-dropdown-toggle"]').click
      page.find('[data-testid="base-dropdown-menu"]').all(".gl-new-dropdown-item")[1].click
    end
  end

  def fill_in_custom_label_stage_fields
    index = page.all('[data-testid="value-stream-stage-fields"]').length
    last_stage = page.all('[data-testid="value-stream-stage-fields"]').last

    within last_stage do
      find('[name*="custom-stage-name-"]').fill_in with: "Cool custom label stage - name #{index}"
      select_dropdown_option_by_value "custom-stage-start-event-", 'Issue label was added'
      select_dropdown_option_by_value "custom-stage-end-event-", 'Issue label was removed'

      select_event_label("[data-testid*='custom-stage-start-event-label-']")
      select_event_label("[data-testid*='custom-stage-end-event-label-']")
    end
  end

  def click_add_stage_button
    click_button(s_('CreateValueStreamForm|Add a stage'))
  end

  def add_custom_stage_to_form
    click_add_stage_button

    fill_in_custom_stage_fields
  end

  def add_custom_label_stage_to_form
    click_add_stage_button

    fill_in_custom_label_stage_fields
  end

  def save_value_stream(custom_value_stream_name)
    fill_in 'create-value-stream-name', with: custom_value_stream_name

    click_button(_('New value stream'))
    wait_for_requests
  end

  def click_save_value_stream_button
    click_button(_('Save value stream'))
  end

  def create_custom_value_stream(custom_value_stream_name)
    toggle_value_stream_dropdown
    find_by_testid('create-value-stream-option').click

    add_custom_stage_to_form
    save_value_stream(custom_value_stream_name)
  end

  def wait_for_stages_to_load(selector = '[data-testid="vsa-path-navigation"]')
    expect(page).to have_selector selector
    wait_for_requests
  end

  def select_group(target_group, ready_selector = '[data-testid="vsa-path-navigation"]')
    visit group_analytics_cycle_analytics_path(target_group)

    wait_for_stages_to_load(ready_selector)
  end

  def select_value_stream(value_stream_name)
    toggle_value_stream_dropdown
    page.find('[data-testid="dropdown-value-streams"]').all('li span').find { |item| item.text == value_stream_name.to_s }.click
    wait_for_requests
  end

  def create_value_stream_aggregation(namespace)
    aggregation = Analytics::CycleAnalytics::Aggregation.safe_create_for_namespace(namespace)
    Analytics::CycleAnalytics::NamespaceAggregatorService.new(aggregation: aggregation).execute
  end

  def select_group_and_custom_value_stream(group, custom_value_stream_name)
    create_value_stream_aggregation(group)

    select_group(group)
    select_value_stream(custom_value_stream_name)
  end

  def select_dropdown_option_by_value(name, value)
    page.within("[data-testid*='#{name}']") do
      toggle_listbox

      wait_for_requests
    end

    select_listbox_item(value)
  end

  def create_commit_referencing_issue(issue, branch_name: generate(:branch))
    project.repository.add_branch(user, branch_name, 'master')
    create_commit("Commit for ##{issue.iid}", issue.project, user, branch_name)
  end

  def create_commit(message, project, user, branch_name, count: 1, commit_time: nil, skip_push_handler: false)
    repository = project.repository
    oldrev = repository.commit(branch_name)&.sha || Gitlab::Git::SHA1_BLANK_SHA

    commit_shas = Array.new(count) do |index|
      commit_sha = repository.create_file(user, generate(:branch), "content", message: message, branch_name: branch_name)
      repository.commit(commit_sha)

      commit_sha
    end

    return if skip_push_handler

    Git::BranchPushService.new(
      project,
      user,
      change: {
        oldrev: oldrev,
        newrev: commit_shas.last,
        ref: 'refs/heads/master'
      }
    ).execute
  end

  def create_cycle(user, project, issue, mr, milestone, pipeline)
    issue.update!(milestone: milestone)
    pipeline.run

    ci_build = create(:ci_build, pipeline: pipeline, status: :success, author: user)

    merge_merge_requests_closing_issue(user, project, issue)
    ProcessCommitWorker.new.perform(project.id, user.id, mr.commits.last.to_hash)

    ci_build
  end

  def create_merge_request_closing_issue(user, project, issue, message: nil, source_branch: nil, commit_message: 'commit message')
    if !source_branch || project.repository.commit(source_branch).blank?
      source_branch = generate(:branch)
      project.repository.add_branch(user, source_branch, 'master')
    end

    # Cycle analytic specs often test with frozen times, which causes metrics to be
    # pinned to the current time. For example, in the plan stage, we assume that an issue
    # milestone has been created before any code has been written. We add a second
    # to ensure that the plan time is positive.
    create_commit(commit_message, project, user, source_branch, commit_time: Time.now + 1.second, skip_push_handler: true)

    opts = {
      title: 'Awesome merge_request',
      description: message || "Fixes #{issue.to_reference}",
      source_branch: source_branch,
      target_branch: 'master'
    }

    mr = MergeRequests::CreateService.new(project: project, current_user: user, params: opts).execute

    mr.approval_state.expire_unapproved_key! if Gitlab.ee?

    NewMergeRequestWorker.new.perform(mr, user)
    mr
  end

  def merge_merge_requests_closing_issue(user, project, issue)
    merge_requests = Issues::ReferencedMergeRequestsService
                       .new(container: project, current_user: user)
                       .closed_by_merge_requests(issue)

    merge_requests.each { |merge_request| MergeRequests::MergeService.new(project: project, current_user: user, params: { sha: merge_request.diff_head_sha }).execute(merge_request) }
  end

  def deploy_master(user, project, environment: 'production')
    dummy_job =
      case environment
      when 'production'
        dummy_production_job(user, project)
      when 'staging'
        dummy_staging_job(user, project)
      else
        raise ArgumentError
      end

    dummy_job.success! # State machine automatically update associated deployment/environment record
  end

  def dummy_production_job(user, project)
    new_dummy_job(user, project, 'production')
  end

  def dummy_staging_job(user, project)
    new_dummy_job(user, project, 'staging')
  end

  def dummy_pipeline(project)
    create(:ci_pipeline,
      sha: project.repository.commit('master').sha,
      ref: 'master',
      source: :push,
      project: project,
      protected: false)
  end

  def new_dummy_job(user, project, environment)
    create(:ci_build,
      :with_deployment,
      project: project,
      user: user,
      environment: environment,
      ref: 'master',
      tag: false,
      name: 'dummy',
      stage: 'dummy',
      pipeline: dummy_pipeline(project),
      protected: false)
  end

  def create_deployment(args)
    project = args[:project]
    environment = project.environments.production.first || create(:environment, :production, project: project)
    create(:deployment, :success, args.merge(environment: environment))

    # this is needed for the DORA API so we have aggregated data
    ::Dora::DailyMetrics::RefreshWorker.new.perform(environment.id, Time.current.to_date.to_s) if Gitlab.ee?
  end

  def vsa_metrics_values
    page.find("[data-testid='vsa-metrics']").all("[data-testid='displayValue']").collect(&:text)
  end

  def vsa_metrics_titles
    page.find("[data-testid='vsa-metrics']").all("[data-testid='title-text']").collect(&:text)
  end
end
