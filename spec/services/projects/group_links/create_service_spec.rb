# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::CreateService, '#execute' do
  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create :project }

  let(:group_access) { Gitlab::Access::DEVELOPER }
  let(:opts) do
    {
      link_group_access: group_access,
      expires_at: nil
    }
  end

  subject { described_class.new(project, user, opts) }

  before do
    group.add_developer(user)
  end

  it 'adds group to project' do
    expect { subject.execute(group) }.to change { project.project_group_links.count }.from(0).to(1)
  end

  it 'updates authorization', :sidekiq_inline do
    expect { subject.execute(group) }.to(
      change { Ability.allowed?(user, :read_project, project) }
        .from(false).to(true))
  end

  it 'returns false if group is blank' do
    expect { subject.execute(nil) }.not_to change { project.project_group_links.count }
  end

  it 'returns error if user is not allowed to share with a group' do
    expect { subject.execute(create(:group)) }.not_to change { project.project_group_links.count }
  end

  context 'with specialized project_authorization workers' do
    let_it_be(:other_user) { create(:user) }

    before do
      group.add_developer(other_user)
    end

    it 'schedules authorization update for users with access to group' do
      expect(AuthorizedProjectsWorker).not_to(
        receive(:bulk_perform_async)
      )
      expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).to(
        receive(:perform_async)
          .with(project.id)
          .and_call_original
      )
      expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
        receive(:bulk_perform_in)
          .with(1.hour,
                array_including([user.id], [other_user.id]),
                batch_delay: 30.seconds, batch_size: 100)
          .and_call_original
      )

      subject.execute(group)
    end
  end
end
