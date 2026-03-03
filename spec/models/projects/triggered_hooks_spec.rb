# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TriggeredHooks, feature_category: :webhooks do
  let_it_be(:project) { create(:project) }

  let_it_be(:universal_push_hook) { create(:project_hook, project: project, push_events: true) }
  let_it_be(:selective_push_hook) { create(:project_hook, :with_push_branch_filter, project: project, push_events: true) }
  let_it_be(:issues_hook) { create(:project_hook, project: project, issues_events: true, push_events: false) }

  let(:wh_service) { instance_double(::WebHookService, async_execute: true) }
  let(:data) { { some: 'data', as: 'json' } }

  def run_hooks(scope, data, relation: ProjectHook.all)
    hooks = described_class.new(scope, data)
    hooks.add_hooks(relation)
    hooks.execute
  end

  it 'executes hooks by scope' do
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

  context 'with hook filters' do
    let_it_be(:filtered_push_hook) do
      create(
        :project_hook,
        project: project,
        push_events: true,
        filter: {
          'push_hooks' => {
            'rules' => [
              { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'failed' }
            ]
          }
        }
      )
    end

    it 'executes hook when filter matches' do
      data = { object_attributes: { status: 'failed' } }

      expect_hook_execution(filtered_push_hook, data, 'push_hooks')

      run_hooks(:push_hooks, data, relation: ProjectHook.where(id: filtered_push_hook.id))
    end

    it 'skips hook when filter does not match' do
      data = { object_attributes: { status: 'success' } }

      expect(WebHookService).not_to receive(:new)

      run_hooks(:push_hooks, data, relation: ProjectHook.where(id: filtered_push_hook.id))
    end

    it 'ignores filters for other scopes' do
      hook = create(
        :project_hook,
        project: project,
        push_events: true,
        filter: {
          'issue_hooks' => {
            'rules' => [
              { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'failed' }
            ]
          }
        }
      )
      data = { object_attributes: { status: 'success' } }

      expect_hook_execution(hook, data, 'push_hooks')

      run_hooks(:push_hooks, data, relation: ProjectHook.where(id: hook.id))
    end

    it 'skips hook when filter field is missing' do
      hook = create(
        :project_hook,
        project: project,
        push_events: true,
        filter: {
          'push_hooks' => {
            'rules' => [
              { 'field' => 'object_attributes.missing', 'operator' => 'eq', 'value' => 'nope' }
            ]
          }
        }
      )
      data = { object_attributes: { status: 'success' } }

      expect(WebHookService).not_to receive(:new)

      run_hooks(:push_hooks, data, relation: ProjectHook.where(id: hook.id))
    end
  end

  context 'with access token hooks' do
    let_it_be(:resource_access_token_hook) { create(:project_hook, project: project, resource_access_token_events: true) }

    it 'executes hook' do
      expect_hook_execution(resource_access_token_hook, data, 'resource_access_token_hooks')

      run_hooks(:resource_access_token_hooks, data)
    end
  end

  context 'with deploy token hooks' do
    let_it_be(:resource_deploy_token_hook) { create(:project_hook, project: project, resource_deploy_token_events: true) }

    it 'executes hook' do
      expect_hook_execution(resource_deploy_token_hook, data, 'resource_deploy_token_hooks')

      run_hooks(:resource_deploy_token_hooks, data)
    end
  end

  context 'with emoji hooks' do
    let_it_be(:emoji_hook) { create(:project_hook, project: project, emoji_events: true) }

    it 'executes hook' do
      expect_hook_execution(emoji_hook, data, 'emoji_hooks')

      run_hooks(:emoji_hooks, data)
    end
  end

  def expect_hook_execution(hook, data, scope)
    expect(WebHookService)
      .to receive(:new)
      .with(hook, data, scope, idempotency_key: anything)
      .and_return(wh_service)
  end
end
