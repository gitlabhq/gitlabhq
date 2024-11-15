# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAuthorizations::Changes, feature_category: :groups_and_projects do
  describe '.apply!' do
    subject(:apply_project_authorization_changes) { project_authorization_changes.apply! }

    shared_examples_for 'does not log any detail' do
      it 'does not log any detail' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        apply_project_authorization_changes
      end
    end

    shared_examples_for 'logs the detail' do |batch_size:|
      it 'logs the detail' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          entire_size: 3,
          message: 'Project authorizations refresh performed with delay',
          total_delay: (3 / batch_size.to_f).ceil * ProjectAuthorizations::Changes::SLEEP_DELAY,
          **Gitlab::ApplicationContext.current
        )

        apply_project_authorization_changes
      end
    end

    shared_examples_for 'publishes AuthorizationsRemovedEvent' do
      it 'publishes a AuthorizationsRemovedEvent event with project id' do
        allow(::Gitlab::EventStore).to receive(:publish_group)
        project_events = project_ids.map do |project_id|
          project_data = { project_id: project_id, user_ids: user_ids }
          project_event = instance_double('::ProjectAuthorizations::AuthorizationsRemovedEvent', data: project_data)

          allow(::ProjectAuthorizations::AuthorizationsRemovedEvent).to receive(:new)
                                                                          .with(data: project_data)
                                                                          .and_return(project_event)
          project_event
        end
        expect(::Gitlab::EventStore).to receive(:publish_group).with(project_events)

        apply_project_authorization_changes
      end
    end

    shared_examples_for 'publishes AuthorizationsAddedEvent' do
      it 'publishes a AuthorizationsAddedEvent event with project ids' do
        allow(::Gitlab::EventStore).to receive(:publish_group)
        project_data = { project_ids: project_ids, user_ids: user_ids }
        project_event = instance_double('::ProjectAuthorizations::AuthorizationsAddedEvent', data: project_data)

        allow(::ProjectAuthorizations::AuthorizationsAddedEvent).to receive(:new)
                                                                        .with(data: project_data)
                                                                        .and_return(project_event)
        expect(::Gitlab::EventStore).to receive(:publish_group).with([project_event])

        apply_project_authorization_changes
      end
    end

    shared_examples_for 'does not publish AuthorizationsRemovedEvent' do
      it 'does not publish a AuthorizationsRemovedEvent event' do
        expect(::Gitlab::EventStore).not_to(
          receive(:publish_group).with(
            array_including(an_instance_of(::ProjectAuthorizations::AuthorizationsRemovedEvent))
          )
        )

        apply_project_authorization_changes
      end
    end

    shared_examples_for 'does not publish AuthorizationsAddedEvent' do
      it 'does not publish a AuthorizationsAddedEvent event' do
        expect(::Gitlab::EventStore).not_to(
          receive(:publish_group).with(
            array_including(an_instance_of(::ProjectAuthorizations::AuthorizationsAddedEvent))
          )
        )

        apply_project_authorization_changes
      end
    end

    context 'when new authorizations should be added' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project_1) { create(:project) }
      let_it_be(:project_2) { create(:project) }
      let_it_be(:project_3) { create(:project) }
      let(:project_ids) { [project_1.id, project_2.id, project_3.id] }
      let(:user_ids) { [user.id] }

      let(:authorizations_to_add) do
        [
          { user_id: user.id, project_id: project_1.id, access_level: Gitlab::Access::MAINTAINER },
          { user_id: user.id, project_id: project_2.id, access_level: Gitlab::Access::MAINTAINER },
          { user_id: user.id, project_id: project_3.id, access_level: Gitlab::Access::MAINTAINER }
        ]
      end

      let(:project_authorization_changes) do
        ProjectAuthorizations::Changes.new do |changes|
          changes.add(authorizations_to_add)
        end
      end

      before do
        # Configure as if a replica database is enabled
        allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(false)
      end

      shared_examples_for 'inserts the rows in batches, as per the `per_batch` size, without a delay between batches' do
        specify do
          expect(project_authorization_changes).not_to receive(:sleep)

          apply_project_authorization_changes

          expect(user.project_authorizations.pluck(:user_id, :project_id,
            :access_level, :is_unique)).to match_array(authorizations_to_add.map(&:values))
        end
      end

      context 'when the total number of records to be inserted is greater than the batch size' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 2)
        end

        it 'inserts the rows in batches, as per the `per_batch` size, with a delay between each batch' do
          expect(ProjectAuthorization).to receive(:insert_all).twice.and_call_original
          expect(project_authorization_changes).to receive(:sleep).twice

          apply_project_authorization_changes

          expect(user.project_authorizations.pluck(:user_id, :project_id,
            :access_level, :is_unique)).to match_array(authorizations_to_add.map(&:values))
        end

        it 'writes is_unique' do
          apply_project_authorization_changes

          expect(user.project_authorizations.pluck(:is_unique)).to all(be(true))
        end

        it_behaves_like 'logs the detail', batch_size: 2
        it_behaves_like 'publishes AuthorizationsAddedEvent'
        it_behaves_like 'does not publish AuthorizationsRemovedEvent'

        context 'when the GitLab installation does not have a replica database configured' do
          before do
            # Configure as if a replica database is not enabled
            allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(true)
          end

          it_behaves_like 'inserts the rows in batches, as per the `per_batch` size, without a delay between batches'
          it_behaves_like 'does not log any detail'
          it_behaves_like 'publishes AuthorizationsAddedEvent'
          it_behaves_like 'does not publish AuthorizationsRemovedEvent'
        end
      end

      context 'when the total number of records to be inserted is less than the batch size' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 5)
        end

        it_behaves_like 'inserts the rows in batches, as per the `per_batch` size, without a delay between batches'
        it_behaves_like 'does not log any detail'
        it_behaves_like 'publishes AuthorizationsAddedEvent'
        it_behaves_like 'does not publish AuthorizationsRemovedEvent'
      end

      describe 'and authorizations should be removed as well' do
        let(:project_authorization_changes) do
          ProjectAuthorizations::Changes.new do |changes|
            changes.add(authorizations_to_add)
            changes.remove_projects_for_user(user, project_ids)
          end
        end

        it_behaves_like 'publishes AuthorizationsAddedEvent'
        it_behaves_like 'does not publish AuthorizationsRemovedEvent'
      end

      context 'when a single user is added to multiple projects' do
        let(:events_batch_size) { 2 }

        before do
          stub_const("#{described_class}::EVENTS_BATCH_SIZE", events_batch_size)
        end

        it 'publishes events in batches for projects' do
          allow(::Gitlab::EventStore).to receive(:publish_group)

          apply_project_authorization_changes

          expect(::Gitlab::EventStore).to have_received(:publish_group) do |events|
            expect(events.size).to eq(2)

            expect(events.map(&:data)).to match_array([
              { project_ids: [project_1.id, project_2.id], user_ids: [user.id] },
              { project_ids: [project_3.id], user_ids: [user.id] }
            ])
          end
        end
      end

      context 'when multiple users are added to multiple projects' do
        let_it_be(:user_1) { create(:user) }
        let_it_be(:user_2) { create(:user) }
        let_it_be(:user_3) { create(:user) }
        let_it_be(:project_1) { create(:project) }
        let_it_be(:project_2) { create(:project) }
        let_it_be(:project_3) { create(:project) }
        let(:project_ids) { [project_1.id, project_2.id, project_3.id] }
        let(:user_ids) { [user_1.id, user_2.id, user_3.id] }

        let(:authorizations_to_add) do
          [
            { user_id: user_1.id, project_id: project_1.id, access_level: Gitlab::Access::MAINTAINER },
            { user_id: user_1.id, project_id: project_2.id, access_level: Gitlab::Access::MAINTAINER },
            { user_id: user_1.id, project_id: project_3.id, access_level: Gitlab::Access::MAINTAINER },
            { user_id: user_2.id, project_id: project_1.id, access_level: Gitlab::Access::MAINTAINER },
            { user_id: user_2.id, project_id: project_2.id, access_level: Gitlab::Access::MAINTAINER },
            { user_id: user_2.id, project_id: project_3.id, access_level: Gitlab::Access::MAINTAINER },
            { user_id: user_3.id, project_id: project_1.id, access_level: Gitlab::Access::MAINTAINER },
            { user_id: user_3.id, project_id: project_2.id, access_level: Gitlab::Access::MAINTAINER },
            { user_id: user_3.id, project_id: project_3.id, access_level: Gitlab::Access::MAINTAINER }
          ]
        end

        let(:events_batch_size) { 2 }

        before do
          stub_const("#{described_class}::EVENTS_BATCH_SIZE", events_batch_size)
        end

        it 'publishes events in batches for both users and projects' do
          allow(::Gitlab::EventStore).to receive(:publish_group)

          apply_project_authorization_changes

          expect(::Gitlab::EventStore).to have_received(:publish_group) do |events|
            expect(events.size).to eq(4)

            expect(events.first).to be_a(ProjectAuthorizations::AuthorizationsAddedEvent)
            expect(events.map(&:data)).to match_array([
              { project_ids: [project_1.id, project_2.id], user_ids: [user_1.id, user_2.id] },
              { project_ids: [project_1.id, project_2.id], user_ids: [user_3.id] },
              { project_ids: [project_3.id], user_ids: [user_1.id, user_2.id] },
              { project_ids: [project_3.id], user_ids: [user_3.id] }
            ])
          end
        end
      end
    end

    context 'when authorizations should be deleted for a project' do
      let_it_be(:project) { create(:project) }
      let_it_be(:user_1) { create(:user) }
      let_it_be(:user_2) { create(:user) }
      let_it_be(:user_3) { create(:user) }
      let_it_be(:user_4) { create(:user) }

      let(:user_ids) { [user_1.id, user_2.id, user_3.id] }
      let(:project_ids) { [project.id] }

      let(:project_authorization_changes) do
        ProjectAuthorizations::Changes.new do |changes|
          changes.remove_users_in_project(project, user_ids)
        end
      end

      before do
        # Configure as if a replica database is enabled
        allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(false)
      end

      before_all do
        create(:project_authorization, user: user_1, project: project)
        create(:project_authorization, user: user_2, project: project)
        create(:project_authorization, user: user_3, project: project)
        create(:project_authorization, user: user_4, project: project)
      end

      shared_examples_for 'removes project authorizations of the users in the current project, without a delay' do
        specify do
          expect(project_authorization_changes).not_to receive(:sleep)

          apply_project_authorization_changes

          expect(project.project_authorizations.pluck(:user_id)).not_to include(*user_ids)
        end
      end

      shared_examples_for 'does not removes project authorizations of the users in the current project' do
        it 'does not delete any project authorization' do
          expect { apply_project_authorization_changes }.not_to change { project.project_authorizations.count }
        end
      end

      context 'when the total number of records to be removed is greater than the batch size' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 2)
        end

        it 'removes project authorizations of the users in the current project, with a delay' do
          expect(project_authorization_changes).to receive(:sleep).twice

          apply_project_authorization_changes

          expect(project.project_authorizations.pluck(:user_id)).not_to include(*user_ids)
        end

        it_behaves_like 'logs the detail', batch_size: 2
        it_behaves_like 'publishes AuthorizationsRemovedEvent'
        it_behaves_like 'does not publish AuthorizationsAddedEvent'

        context 'when the GitLab installation does not have a replica database configured' do
          before do
            # Configure as if a replica database is not enabled
            allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(true)
          end

          it_behaves_like 'removes project authorizations of the users in the current project, without a delay'
          it_behaves_like 'does not log any detail'
          it_behaves_like 'publishes AuthorizationsRemovedEvent'
          it_behaves_like 'does not publish AuthorizationsAddedEvent'
        end
      end

      context 'when the total number of records to be removed is less than the batch size' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 5)
        end

        it_behaves_like 'removes project authorizations of the users in the current project, without a delay'
        it_behaves_like 'does not log any detail'
        it_behaves_like 'publishes AuthorizationsRemovedEvent'
        it_behaves_like 'does not publish AuthorizationsAddedEvent'
      end

      context 'when the user_ids list is empty' do
        let(:user_ids) { [] }

        it_behaves_like 'does not removes project authorizations of the users in the current project'
        it_behaves_like 'does not publish AuthorizationsRemovedEvent'
        it_behaves_like 'does not publish AuthorizationsAddedEvent'
      end

      context 'when the user_ids list is nil' do
        let(:user_ids) { nil }

        it_behaves_like 'does not removes project authorizations of the users in the current project'
        it_behaves_like 'does not publish AuthorizationsRemovedEvent'
        it_behaves_like 'does not publish AuthorizationsAddedEvent'
      end
    end

    describe 'when authorizations should be deleted for an user' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project_1) { create(:project) }
      let_it_be(:project_2) { create(:project) }
      let_it_be(:project_3) { create(:project) }
      let_it_be(:project_4) { create(:project) }

      let(:project_ids) { [project_1.id, project_2.id, project_3.id] }
      let(:user_ids) { [user.id] }

      let(:project_authorization_changes) do
        ProjectAuthorizations::Changes.new do |changes|
          changes.remove_projects_for_user(user, project_ids)
        end
      end

      before do
        # Configure as if a replica database is enabled
        allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(false)
      end

      before_all do
        create(:project_authorization, user: user, project: project_1)
        create(:project_authorization, user: user, project: project_2)
        create(:project_authorization, user: user, project: project_3)
        create(:project_authorization, user: user, project: project_4)
      end

      shared_examples_for 'removes project authorizations of projects from the current user, without a delay' do
        specify do
          expect(project_authorization_changes).not_to receive(:sleep)

          apply_project_authorization_changes

          expect(user.project_authorizations.pluck(:project_id)).not_to include(*project_ids)
        end
      end

      shared_examples_for 'does not removes any project authorizations from the current user' do
        it 'does not delete any project authorization' do
          expect { apply_project_authorization_changes }.not_to change { user.project_authorizations.count }
        end
      end

      context 'when the total number of records to be removed is greater than the batch size' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 2)
        end

        it 'removes the project authorizations of projects from the current user, with a delay between each batch' do
          expect(project_authorization_changes).to receive(:sleep).twice

          apply_project_authorization_changes

          expect(user.project_authorizations.pluck(:project_id)).not_to include(*project_ids)
        end

        it_behaves_like 'logs the detail', batch_size: 2
        it_behaves_like 'publishes AuthorizationsRemovedEvent'
        it_behaves_like 'does not publish AuthorizationsAddedEvent'

        context 'when the GitLab installation does not have a replica database configured' do
          before do
            # Configure as if a replica database is not enabled
            allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(true)
          end

          it_behaves_like 'removes project authorizations of projects from the current user, without a delay'
          it_behaves_like 'does not log any detail'
          it_behaves_like 'publishes AuthorizationsRemovedEvent'
          it_behaves_like 'does not publish AuthorizationsAddedEvent'
        end
      end

      context 'when the total number of records to be removed is less than the batch size' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 5)
        end

        it_behaves_like 'removes project authorizations of projects from the current user, without a delay'
        it_behaves_like 'does not log any detail'
        it_behaves_like 'publishes AuthorizationsRemovedEvent'
        it_behaves_like 'does not publish AuthorizationsAddedEvent'
      end

      context 'when the project_ids list is empty' do
        let(:project_ids) { [] }

        it_behaves_like 'does not removes any project authorizations from the current user'
        it_behaves_like 'does not publish AuthorizationsRemovedEvent'
        it_behaves_like 'does not publish AuthorizationsAddedEvent'
      end

      context 'when the user_ids list is nil' do
        let(:project_ids) { nil }

        it_behaves_like 'does not removes any project authorizations from the current user'
        it_behaves_like 'does not publish AuthorizationsRemovedEvent'
        it_behaves_like 'does not publish AuthorizationsAddedEvent'
      end
    end
  end
end
