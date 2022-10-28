# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::ApiService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_projects: [project]) }

  it 'creates a protected branch with prefilled defaults' do
    expect(::ProtectedBranches::CreateService).to receive(:new).with(
      project, user, hash_including(
                       push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
                       merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
                     )
    ).and_call_original

    expect(described_class.new(project, user, { name: 'new name' }).create).to be_valid
  end

  it 'updates a protected branch without prefilled defaults' do
    protected_branch = create(:protected_branch, project: project, allow_force_push: true)

    expect(::ProtectedBranches::UpdateService).to receive(:new).with(
      project, user, hash_including(
                       push_access_levels_attributes: [],
                       merge_access_levels_attributes: []
                     )
    ).and_call_original

    expect do
      expect(described_class.new(project, user, { name: 'new name' }).update(protected_branch)).to be_valid
    end.not_to change { protected_branch.reload.allow_force_push }
  end
end
