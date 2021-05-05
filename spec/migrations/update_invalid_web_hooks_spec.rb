# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateInvalidWebHooks do
  let(:web_hooks) { table(:web_hooks) }
  let(:groups) { table(:namespaces) }
  let(:projects) { table(:projects) }

  before do
    group = groups.create!(name: 'gitlab', path: 'gitlab-org')
    project = projects.create!(namespace_id: group.id)

    web_hooks.create!(group_id: group.id, type: 'GroupHook')
    web_hooks.create!(project_id: project.id, type: 'ProjectHook')
    web_hooks.create!(group_id: group.id, project_id: project.id, type: 'ProjectHook')
  end

  it 'clears group_id when ProjectHook type and project_id are present', :aggregate_failures do
    expect(web_hooks.where.not(group_id: nil).where.not(project_id: nil).count).to eq(1)

    migrate!

    expect(web_hooks.where.not(group_id: nil).where.not(project_id: nil).count).to eq(0)
    expect(web_hooks.where(type: 'GroupHook').count).to eq(1)
    expect(web_hooks.where(type: 'ProjectHook').count).to eq(2)
  end
end
