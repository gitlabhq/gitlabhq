# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ChangeWebHookEventsDefault do
  let(:web_hooks) { table(:web_hooks) }
  let(:projects) { table(:projects) }
  let(:groups) { table(:namespaces) }

  let(:group) { groups.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create!(name: 'gitlab', path: 'gitlab', namespace_id: group.id) }
  let(:hook) { web_hooks.create!(project_id: project.id, type: 'ProjectHook') }
  let(:group_hook) { web_hooks.create!(group_id: group.id, type: 'GroupHook') }

  before do
    # Simulate the wrong schema
    %w(push_events issues_events merge_requests_events tag_push_events).each do |column|
      ActiveRecord::Base.connection.execute "ALTER TABLE web_hooks ALTER COLUMN #{column} DROP DEFAULT"
    end
  end

  it 'sets default values' do
    migrate!

    expect(hook.push_events).to be true
    expect(hook.issues_events).to be false
    expect(hook.merge_requests_events).to be false
    expect(hook.tag_push_events).to be false

    expect(group_hook.push_events).to be true
    expect(group_hook.issues_events).to be false
    expect(group_hook.merge_requests_events).to be false
    expect(group_hook.tag_push_events).to be false
  end
end
