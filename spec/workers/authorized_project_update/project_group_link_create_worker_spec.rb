# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectGroupLinkCreateWorker do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:group_project) { create(:project, group: group) }
  let_it_be(:shared_with_group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  let(:access_level) { Gitlab::Access::MAINTAINER }

  subject(:worker) { described_class.new }

  it 'calls AuthorizedProjectUpdate::ProjectCreateService' do
    expect_next_instance_of(AuthorizedProjectUpdate::ProjectGroupLinkCreateService) do |service|
      expect(service).to(receive(:execute))
    end

    worker.perform(group_project.id, shared_with_group.id)
  end

  it 'returns ServiceResponse.success' do
    result = worker.perform(group_project.id, shared_with_group.id)

    expect(result.success?).to be_truthy
  end

  context 'idempotence' do
    before do
      create(:group_member, group: shared_with_group, user: user, access_level: access_level)
      create(:project_group_link, project: group_project, group: shared_with_group)
      ProjectAuthorization.delete_all
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { [group_project.id, shared_with_group.id] }

      it 'creates project authorization' do
        subject

        project_authorization = ProjectAuthorization.where(
          project_id: group_project.id,
          user_id: user.id,
          access_level: access_level)

        expect(project_authorization).to exist
        expect(ProjectAuthorization.count).to eq(1)
      end
    end
  end
end
