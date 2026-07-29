# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::RefreshAuthorizedProjectsService, feature_category: :user_management do
  include ExclusiveLeaseHelpers

  # We're using let! here so that any expectations for the service class are not
  # triggered twice.
  let!(:project) { create(:project) }

  let(:user) { project.namespace.first_owner }
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
          described_class.new(user, incorrect_auth_found_callback: callback)
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
          described_class.new(user, missing_auth_found_callback: callback)
        end

        it 'is called' do
          ProjectAuthorization.delete_all

          expect(callback).to receive(:call).with(project.id, Gitlab::Access::OWNER).once

          service.execute
        end
      end
    end

    it 'logs the duration statistics' do
      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        hash_including(
          event: 'authorized_projects_refresh',
          user_id: user.id,
          obtain_redis_lease_duration_s: anything,
          find_records_due_for_refresh_duration_s: anything,
          update_authorizations_duration_s: anything
        )
      )
      service.execute
    end
  end

  describe '#execute_without_lease' do
    before do
      user.project_authorizations.delete_all
    end

    it 'updates the authorized projects of the user' do
      project2 = create(:project)
      project_authorization = user.project_authorizations
        .create!(project: project2, access_level: Gitlab::Access::MAINTAINER)

      to_be_removed = [project_authorization.project_id]

      to_be_added = [
        { user_id: user.id, project_id: project.id, access_level: Gitlab::Access::OWNER }
      ]

      expect(service).to receive(:update_authorizations)
        .with(to_be_removed, to_be_added)

      service.execute_without_lease
    end

    it 'sets the access level of a project to the highest available level' do
      user.project_authorizations.delete_all

      project_authorization = user.project_authorizations
        .create!(project: project, access_level: Gitlab::Access::DEVELOPER)

      to_be_removed = [project_authorization.project_id]

      to_be_added = [
        { user_id: user.id, project_id: project.id, access_level: Gitlab::Access::OWNER }
      ]

      expect(service).to receive(:update_authorizations)
        .with(to_be_removed, to_be_added)

      service.execute_without_lease
    end

    it 'updates project_authorizations_recalculated_at', :freeze_time do
      default_date = Time.zone.local('2010')
      expect do
        service.execute_without_lease
      end.to change { user.project_authorizations_recalculated_at }.from(default_date).to(Time.zone.now)
    end

    it 'returns a User' do
      expect(service.execute_without_lease).to be_an_instance_of(User)
    end
  end

  describe '#update_authorizations' do
    context 'when there are no rows to add and remove' do
      it 'does not change authorizations' do
        expect { service.update_authorizations([], []) }.to not_change { user.project_authorizations.count }
      end
    end

    it 'removes authorizations that should be removed' do
      authorization = user.project_authorizations.find_by(project_id: project.id)

      service.update_authorizations([authorization.project_id])

      expect(user.project_authorizations).to be_empty
    end

    it 'inserts authorizations that should be added' do
      user.project_authorizations.delete_all

      to_be_added = [
        { user_id: user.id, project_id: project.id, access_level: Gitlab::Access::MAINTAINER }
      ]

      service.update_authorizations([], to_be_added)

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

      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        hash_including(
          event: 'authorized_projects_refresh',
          user_id: user.id,
          'authorized_projects_refresh.source': source,
          'authorized_projects_refresh.rows_deleted_count': 0,
          'authorized_projects_refresh.rows_added_count': 1,
          'authorized_projects_refresh.rows_deleted_slice': [],
          'authorized_projects_refresh.rows_added_slice': [[user.id, project.id, Gitlab::Access::MAINTAINER, true]]
        )
      )

      to_be_added = [
        { user_id: user.id, project_id: project.id, access_level: Gitlab::Access::MAINTAINER }
      ]

      service.update_authorizations([], to_be_added)
    end

    it 'includes the related_class from the ambient context as the trigger' do
      user.project_authorizations.delete_all

      to_be_added = [
        { user_id: user.id, project_id: project.id, access_level: Gitlab::Access::MAINTAINER }
      ]

      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        hash_including('authorized_projects_refresh.trigger': 'SomeCaller')
      )

      Gitlab::ApplicationContext.with_context(related_class: 'SomeCaller') do
        service.update_authorizations([], to_be_added)
      end
    end

    describe 'safety-net refresh metrics', :prometheus do
      let(:to_be_removed) { [project.id] }
      let(:to_be_added) do
        [{ user_id: user.id, project_id: project.id, access_level: Gitlab::Access::MAINTAINER }]
      end

      let(:service) { described_class.new(user) }
      let(:counter) { Gitlab::Metrics.counter(:gitlab_authorized_projects_safety_net_refresh_rows_total, 'test') }

      before do
        allow(Gitlab::Metrics).to receive(:counter).and_return(counter)
      end

      context 'when the refresh is marked with the safety-net purpose' do
        it 'increments the refresh trend counter for each direction, including the trigger label' do
          expect(counter).to receive(:increment)
            .with(hash_including(trigger: 'SomeCaller', direction: 'deleted'), to_be_removed.size)
          expect(counter).to receive(:increment)
            .with(hash_including(trigger: 'SomeCaller', direction: 'added'), to_be_added.size)

          Gitlab::ApplicationContext.with_raw_context(
            authorized_projects_refresh_purpose: UserProjectAccessChangedService::SAFETY_NET_REFRESH_PURPOSE
          ) do
            Gitlab::ApplicationContext.with_context(related_class: 'SomeCaller') do
              service.update_authorizations(to_be_removed, to_be_added)
            end
          end
        end
      end

      context "when the refresh isn't marked with the safety-net purpose" do
        it 'does not increment the refresh trend counter' do
          expect(counter).not_to receive(:increment)

          service.update_authorizations(to_be_removed, to_be_added)
        end
      end
    end
  end
end
