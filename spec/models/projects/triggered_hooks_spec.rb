# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TriggeredHooks do
  let_it_be(:project) { create(:project) }

  let_it_be(:universal_push_hook) { create(:project_hook, project: project, push_events: true) }
  let_it_be(:selective_push_hook) { create(:project_hook, :with_push_branch_filter, project: project, push_events: true) }
  let_it_be(:issues_hook) { create(:project_hook, project: project, issues_events: true, push_events: false) }

  let(:wh_service) { instance_double(::WebHookService, async_execute: true) }

  def run_hooks(scope, data)
    hooks = described_class.new(scope, data)
    hooks.add_hooks(ProjectHook.all)
    hooks.execute
  end

  it 'executes hooks by scope' do
    data = { some: 'data', as: 'json' }

    expect_hook_execution(issues_hook, data, 'issue_hooks')

    run_hooks(:issue_hooks, data)
  end

  it 'applies branch filters, when they match' do
    data = { some: 'data', as: 'json', ref: "refs/heads/#{generate(:branch)}" }

    expect_hook_execution(universal_push_hook, data, 'push_hooks')
    expect_hook_execution(selective_push_hook, data, 'push_hooks')

    run_hooks(:push_hooks, data)
  end

  it 'applies branch filters, when they do not match' do
    data = { some: 'data', as: 'json', ref: "refs/heads/master}" }

    expect_hook_execution(universal_push_hook, data, 'push_hooks')

    run_hooks(:push_hooks, data)
  end

  def expect_hook_execution(hook, data, scope)
    expect(WebHookService).to receive(:new).with(hook, data, scope).and_return(wh_service)
  end
end
