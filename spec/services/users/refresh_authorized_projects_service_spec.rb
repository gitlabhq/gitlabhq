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

    it 'logs the details of the refresh' do
      source = :foo
      service = described_class.new(user, source: source)
      user.project_authorizations.delete_all

      expect(Gitlab::AppJsonLogger).to(
        receive(:info)
          .with(event: 'authorized_projects_refresh',
                user_id: user.id,
                'authorized_projects_refresh.source': source,
                'authorized_projects_refresh.rows_deleted_count': 0,
                'authorized_projects_refresh.rows_added_count': 1,
                'authorized_projects_refresh.rows_deleted_slice': [],
                'authorized_projects_refresh.rows_added_slice': [[user.id, project.id, Gitlab::Access::MAINTAINER]])
      )

      service.update_authorizations([], [[user.id, project.id, Gitlab::Access::MAINTAINER]])
    end
  end
end
