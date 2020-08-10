# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::RefreshAuthorizedProjectsService do
  include ExclusiveLeaseHelpers

  # We're using let! here so that any expectations for the service class are not
  # triggered twice.
  let!(:project) { create(:project) }

  let(:user) { project.namespace.owner }
  let(:service) { described_class.new(user) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'refreshes the authorizations using a lease' do
      lease_key = "refresh_authorized_projects:#{user.id}"

      expect_to_obtain_exclusive_lease(lease_key, 'uuid')
      expect_to_cancel_exclusive_lease(lease_key, 'uuid')
      expect(service).to receive(:execute_without_lease)

      service.execute
    end

    context 'callbacks' do
      let(:callback) { double('callback') }

      context 'incorrect_auth_found_callback callback' do
        let(:user) { create(:user) }
        let(:service) do
          described_class.new(user,
                              incorrect_auth_found_callback: callback)
        end

        it 'is called' do
          access_level = Gitlab::Access::DEVELOPER
          create(:project_authorization, user: user, project: project, access_level: access_level)

          expect(callback).to receive(:call).with(project.id, access_level).once

          service.execute
        end
      end

      context 'missing_auth_found_callback callback' do
        let(:service) do
          described_class.new(user,
                              missing_auth_found_callback: callback)
        end

        it 'is called' do
          ProjectAuthorization.delete_all

          expect(callback).to receive(:call).with(project.id, Gitlab::Access::MAINTAINER).once

          service.execute
        end
      end
    end
  end

  describe '#execute_without_lease' do
    before do
      user.project_authorizations.delete_all
    end

    it 'updates the authorized projects of the user' do
      project2 = create(:project)
      to_remove = user.project_authorizations
        .create!(project: project2, access_level: Gitlab::Access::MAINTAINER)

      expect(service).to receive(:update_authorizations)
        .with([to_remove.project_id], [[user.id, project.id, Gitlab::Access::MAINTAINER]])

      service.execute_without_lease
    end

    it 'removes duplicate entries' do
      [Gitlab::Access::MAINTAINER, Gitlab::Access::REPORTER].each do |access_level|
        user.project_authorizations.create!(project: project, access_level: access_level)
      end

      expect(service).to(
        receive(:update_authorizations)
          .with([project.id], [[user.id, project.id, Gitlab::Access::MAINTAINER]])
          .and_call_original)

      service.execute_without_lease

      expect(user.project_authorizations.count).to eq(1)
      project_authorization = ProjectAuthorization.where(
        project_id: project.id,
        user_id: user.id,
        access_level: Gitlab::Access::MAINTAINER)
      expect(project_authorization).to exist
    end

    it 'sets the access level of a project to the highest available level' do
      user.project_authorizations.delete_all

      to_remove = user.project_authorizations
        .create!(project: project, access_level: Gitlab::Access::DEVELOPER)

      expect(service).to receive(:update_authorizations)
        .with([to_remove.project_id], [[user.id, project.id, Gitlab::Access::MAINTAINER]])

      service.execute_without_lease
    end

    it 'returns a User' do
      expect(service.execute_without_lease).to be_an_instance_of(User)
    end
  end

  describe '#update_authorizations' do
    context 'when there are no rows to add and remove' do
      it 'does not change authorizations' do
        expect(user).not_to receive(:remove_project_authorizations)
        expect(ProjectAuthorization).not_to receive(:insert_authorizations)

        service.update_authorizations([], [])
      end
    end

    it 'removes authorizations that should be removed' do
      authorization = user.project_authorizations.find_by(project_id: project.id)

      service.update_authorizations([authorization.project_id])

      expect(user.project_authorizations).to be_empty
    end

    it 'inserts authorizations that should be added' do
      user.project_authorizations.delete_all

      service.update_authorizations([], [[user.id, project.id, Gitlab::Access::MAINTAINER]])

      authorizations = user.project_authorizations

      expect(authorizations.length).to eq(1)
      expect(authorizations[0].user_id).to eq(user.id)
      expect(authorizations[0].project_id).to eq(project.id)
      expect(authorizations[0].access_level).to eq(Gitlab::Access::MAINTAINER)
    end
  end

  describe '#fresh_access_levels_per_project' do
    let(:hash) { service.fresh_access_levels_per_project }

    it 'returns a Hash' do
      expect(hash).to be_an_instance_of(Hash)
    end

    it 'sets the keys to the project IDs' do
      expect(hash.keys).to eq([project.id])
    end

    it 'sets the values to the access levels' do
      expect(hash.values).to eq([Gitlab::Access::MAINTAINER])
    end

    context 'personal projects' do
      it 'includes the project with the right access level' do
        expect(hash[project.id]).to eq(Gitlab::Access::MAINTAINER)
      end
    end

    context 'projects the user is a member of' do
      let!(:other_project) { create(:project) }

      before do
        other_project.team.add_reporter(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::REPORTER)
      end
    end

    context 'projects of groups the user is a member of' do
      let(:group) { create(:group) }
      let!(:other_project) { create(:project, group: group) }

      before do
        group.add_owner(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::OWNER)
      end
    end

    context 'projects of subgroups of groups the user is a member of' do
      let(:group) { create(:group) }
      let(:nested_group) { create(:group, parent: group) }
      let!(:other_project) { create(:project, group: nested_group) }

      before do
        group.add_maintainer(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::MAINTAINER)
      end
    end

    context 'projects shared with groups the user is a member of' do
      let(:group) { create(:group) }
      let(:other_project) { create(:project) }
      let!(:project_group_link) { create(:project_group_link, project: other_project, group: group, group_access: Gitlab::Access::GUEST) }

      before do
        group.add_maintainer(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::GUEST)
      end
    end

    context 'projects shared with subgroups of groups the user is a member of' do
      let(:group) { create(:group) }
      let(:nested_group) { create(:group, parent: group) }
      let(:other_project) { create(:project) }
      let!(:project_group_link) { create(:project_group_link, project: other_project, group: nested_group, group_access: Gitlab::Access::DEVELOPER) }

      before do
        group.add_maintainer(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::DEVELOPER)
      end
    end
  end

  describe '#current_authorizations_per_project' do
    let(:hash) { service.current_authorizations_per_project }

    it 'returns a Hash' do
      expect(hash).to be_an_instance_of(Hash)
    end

    it 'sets the keys to the project IDs' do
      expect(hash.keys).to eq([project.id])
    end

    it 'sets the values to the project authorization rows' do
      expect(hash.values.length).to eq(1)

      value = hash.values[0]

      expect(value.project_id).to eq(project.id)
      expect(value.access_level).to eq(Gitlab::Access::MAINTAINER)
    end
  end

  describe '#current_authorizations' do
    context 'without authorizations' do
      it 'returns an empty list' do
        user.project_authorizations.delete_all

        expect(service.current_authorizations.empty?).to eq(true)
      end
    end

    context 'with an authorization' do
      let(:row) { service.current_authorizations.take }

      it 'returns the currently authorized projects' do
        expect(service.current_authorizations.length).to eq(1)
      end

      it 'includes the project ID for every row' do
        expect(row.project_id).to eq(project.id)
      end

      it 'includes the access level for every row' do
        expect(row.access_level).to eq(Gitlab::Access::MAINTAINER)
      end
    end
  end

  describe '#fresh_authorizations' do
    it 'returns the new authorized projects' do
      expect(service.fresh_authorizations.length).to eq(1)
    end

    it 'returns the highest access level' do
      project.team.add_guest(user)

      rows = service.fresh_authorizations.to_a

      expect(rows.length).to eq(1)
      expect(rows.first.access_level).to eq(Gitlab::Access::MAINTAINER)
    end

    context 'every returned row' do
      let(:row) { service.fresh_authorizations.take }

      it 'includes the project ID' do
        expect(row.project_id).to eq(project.id)
      end

      it 'includes the access level' do
        expect(row.access_level).to eq(Gitlab::Access::MAINTAINER)
      end
    end
  end
end
