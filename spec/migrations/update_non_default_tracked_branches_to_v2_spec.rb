# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateNonDefaultTrackedBranchesToV2, migration: :gitlab_sec, feature_category: :vulnerability_management do
  let(:tracked_contexts) { table(:security_project_tracked_contexts) }

  before do
    tracked_contexts.create!(project_id: 1, is_default: true, context_name: "default", uuid_version: 1)
    tracked_contexts.create!(project_id: 1, is_default: false, context_name: "branch", uuid_version: 1)
    tracked_contexts.create!(project_id: 1, is_default: false, context_name: "dev", uuid_version: 1)
    tracked_contexts.create!(project_id: 2, is_default: true, context_name: "default", uuid_version: 2)
    tracked_contexts.create!(project_id: 2, is_default: false, context_name: "branch", uuid_version: 2)
  end

  it 'sets uuid_version to 2 for non-default tracked contexts' do
    project_1 = tracked_contexts.where(project_id: 1)
    project_2 = tracked_contexts.where(project_id: 2)

    expect(project_1.where(uuid_version: 1).count).to eq(3)
    expect(project_1.where(uuid_version: 2).count).to eq(0)
    expect(project_2.where(uuid_version: 1).count).to eq(0)
    expect(project_2.where(uuid_version: 2).count).to eq(2)

    migrate!

    expect(project_1.where(uuid_version: 1).count).to eq(1)
    expect(project_1.where(uuid_version: 2).count).to eq(2)
    expect(project_2.where(uuid_version: 1).count).to eq(0)
    expect(project_2.where(uuid_version: 2).count).to eq(2)
  end
end
