# frozen_string_literal: true

require 'spec_helper'

describe AuthorizedProjectUpdate::ProjectCreateWorker do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:group_project) { create(:project, group: group) }
  let_it_be(:group_user) { create(:user) }

  let(:access_level) { Gitlab::Access::MAINTAINER }

  subject(:worker) { described_class.new }

  it 'calls AuthorizedProjectUpdate::ProjectCreateService' do
    expect_next_instance_of(AuthorizedProjectUpdate::ProjectCreateService) do |service|
      expect(service).to(receive(:execute))
    end

    worker.perform(group_project.id)
  end

  it 'returns ServiceResponse.success' do
    result = worker.perform(group_project.id)

    expect(result.success?).to be_truthy
  end

  context 'idempotence' do
    before do
      create(:group_member, access_level: Gitlab::Access::MAINTAINER, group: group, user: group_user)
      ProjectAuthorization.delete_all
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { group_project.id }

      it 'creates project authorization' do
        subject

        project_authorization = ProjectAuthorization.where(
          project_id: group_project.id,
          user_id: group_user.id,
          access_level: access_level)

        expect(project_authorization).to exist
        expect(ProjectAuthorization.count).to eq(1)
      end
    end
  end
end
