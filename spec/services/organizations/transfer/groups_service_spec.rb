# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Transfer::GroupsService, :aggregate_failures, feature_category: :organization do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }
  let_it_be(:user) { create(:user, organization: old_organization) }
  let_it_be_with_refind(:group) { create(:group, organization: old_organization) }

  let(:service) { described_class.new(group: group, new_organization: new_organization, current_user: user) }

  before_all do
    group.add_owner(user)
    new_organization.add_owner(user)
  end

  describe '#execute' do
    context 'when transfer is successful' do
      let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
      let_it_be_with_refind(:nested_subgroup) { create(:group, parent: subgroup, organization: old_organization) }
      let_it_be_with_refind(:project) { create(:project, namespace: group, organization: old_organization) }
      let_it_be_with_refind(:subgroup_project) do
        create(:project, namespace: subgroup, organization: old_organization)
      end

      let_it_be_with_refind(:nested_project) do
        create(:project, namespace: nested_subgroup, organization: old_organization)
      end

      it 'returns success ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_success
        expect(result.message).to be_nil
      end

      it 'executes within a database transaction' do
        expect(Group).to receive(:transaction).and_call_original

        service.execute
      end

      it 'updates organization_id for group, all descendants and projects' do
        service.execute

        expect(group.reload.organization_id).to eq(new_organization.id)
        expect(subgroup.reload.organization_id).to eq(new_organization.id)
        expect(nested_subgroup.reload.organization_id).to eq(new_organization.id)

        expect(project.reload.organization_id).to eq(new_organization.id)
        expect(subgroup_project.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.reload.organization_id).to eq(new_organization.id)

        expect(project.project_namespace.reload.organization_id).to eq(new_organization.id)
        expect(subgroup_project.project_namespace.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.project_namespace.reload.organization_id).to eq(new_organization.id)

        expect(group).to be_valid
        expect(subgroup).to be_valid
        expect(nested_subgroup).to be_valid
        expect(project).to be_valid
        expect(subgroup_project).to be_valid
        expect(nested_project).to be_valid
        expect(project.project_namespace).to be_valid
        expect(subgroup_project.project_namespace).to be_valid
        expect(nested_project.project_namespace).to be_valid
      end

      describe 'visibility level updates' do
        context 'when new organization has lower visibility than some groups/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PRIVATE, owners: user) }
          let_it_be_with_refind(:public_subgroup) do
            create(:group, :public, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_subgroup) do
            create(:group, :internal, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:private_subgroup) do
            create(:group, :private, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:public_project) do
            create(:project, :public, namespace: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_project) do
            create(:project, :internal, namespace: subgroup, organization: old_organization)
          end

          let_it_be_with_refind(:private_project) do
            create(:project, :private, namespace: group, organization: old_organization)
          end

          it 'updates visibility for groups with higher visibility than organization' do
            service.execute

            expect(public_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)

            expect(public_subgroup).to be_valid
            expect(internal_subgroup).to be_valid
          end

          it 'does not update visibility for groups with lower or equal visibility' do
            service.execute

            expect(private_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(private_subgroup).to be_valid
          end

          it 'updates visibility for projects with higher visibility than organization' do
            service.execute

            expect(public_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)

            expect(public_project).to be_valid
            expect(internal_project).to be_valid
          end

          it 'updates visibility for project namespaces with higher visibility' do
            service.execute

            expect(public_project.project_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_project.project_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)

            expect(public_project).to be_valid
            expect(internal_project).to be_valid
          end

          it 'does not update visibility for projects with lower or equal visibility' do
            service.execute

            expect(private_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(private_project).to be_valid
          end
        end

        context 'when new organization has higher visibility than some groups/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PUBLIC, owners: user) }
          let_it_be_with_refind(:private_subgroup) do
            create(:group, :private, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_subgroup) do
            create(:group, :internal, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:private_project) do
            create(:project, :private, namespace: group, organization: old_organization)
          end

          it 'does not update visibility for groups with lower visibility' do
            service.execute

            expect(private_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)

            expect(private_subgroup).to be_valid
            expect(internal_subgroup).to be_valid
          end

          it 'does not update visibility for projects with lower visibility' do
            service.execute

            expect(private_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(private_project).to be_valid
          end
        end
      end

      it 'logs successful transfer with correct payload' do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original

        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: "Group was transferred to a new organization",
            group_path: group.full_path,
            group_id: group.id,
            new_organization_path: new_organization.full_path,
            new_organization_id: new_organization.id,
            error_message: nil
          )
        ).and_call_original

        service.execute
      end

      it 'publishes a GroupTransferredEvent' do
        expect { service.execute }.to publish_event(Organizations::GroupTransferredEvent)
          .with(
            group_id: group.id,
            old_organization_id: old_organization.id,
            new_organization_id: new_organization.id
          )
      end

      # Organizations::ActivateService wraps this service in its own transaction and
      # rolls it back when a later step fails.
      it 'does not publish a GroupTransferredEvent when a wrapping transaction rolls back' do
        expect do
          ApplicationRecord.transaction do
            expect(service.execute).to be_success

            raise ActiveRecord::Rollback
          end
        end.not_to publish_event(Organizations::GroupTransferredEvent)
      end

      context 'for runner transfers' do
        it 'enqueues TransferOrganizationWorker with correct arguments' do
          expect(Ci::Runners::TransferOrganizationWorker).to receive(:perform_async).with(
            group.id, old_organization.id, new_organization.id
          )

          service.execute
        end

        it 'does not enqueue TransferOrganizationWorker when the transfer fails' do
          # Raised from the last step inside the transaction, so anything scheduled
          # before it would already have been enqueued.
          allow(service).to receive(:publish_event).and_raise(StandardError, 'Transfer failed')

          expect(Ci::Runners::TransferOrganizationWorker).not_to receive(:perform_async)

          expect(service.execute).to be_error
        end
      end

      context 'for oauth applications' do
        it 'updates organization_id for group-owned oauth applications' do
          app = create(:oauth_application, owner_id: group.id, owner_type: 'Namespace',
            organization: old_organization)

          service.execute

          expect(app.reload.organization_id).to eq(new_organization.id)
        end

        it 'updates organization_id for subgroup-owned oauth applications' do
          app = create(:oauth_application, owner_id: subgroup.id, owner_type: 'Namespace',
            organization: old_organization)

          service.execute

          expect(app.reload.organization_id).to eq(new_organization.id)
        end

        it 'does not update user-owned oauth applications' do
          user_app = create(:oauth_application, owner: user, organization: old_organization)

          expect { service.execute }.not_to change { user_app.reload.organization_id }
        end

        it 'records an upsert outbox row carrying the new organization for the moved application',
          :aggregate_failures do
          app = create(:oauth_application, owner_id: group.id, owner_type: 'Namespace',
            organization: old_organization)

          expect { service.execute }
            .to change { Authn::IamOutbox.where(entity_id: app.id, event_type: :upsert).count }.by(1)

          row = Authn::IamOutbox.where(
            entity_id: app.id, event_type: :upsert, organization_id: new_organization.id
          ).sole
          expect(row).to have_attributes(entity_type: 'oauth_application', payload: {})
        end

        it 'schedules an upsert drain for the moved application' do
          app = create(:oauth_application, owner_id: group.id, owner_type: 'Namespace',
            organization: old_organization)

          expect(Authn::IamReplication::DrainWorker).to receive(:bulk_perform_in)
            .with(Authn::IamReplication::DrainWorker::SCHEDULE_DELAY,
              include(['oauth_application', app.id, 'upsert']))

          service.execute
        end

        it 'records no additional outbox row when the transfer is replayed after a successful run' do
          app = create(:oauth_application, owner_id: group.id, owner_type: 'Namespace',
            organization: old_organization)

          service.execute

          replay = described_class.new(group: group.reset, new_organization: new_organization, current_user: user)

          expect { replay.execute }.not_to change {
            Authn::IamOutbox.where(
              entity_id: app.id, event_type: :upsert, organization_id: new_organization.id
            ).count
          }
        end

        it 'schedules no drain when the transfer rolls back' do
          create(:oauth_application, owner_id: group.id, owner_type: 'Namespace',
            organization: old_organization)

          # Raised after the applications are captured, but still inside the transaction.
          allow(service).to receive(:publish_event).and_raise(ActiveRecord::Rollback)

          expect(Authn::IamReplication::DrainWorker).not_to receive(:bulk_perform_in)

          service.execute
        end

        context 'when IAM replication is disabled' do
          before do
            stub_feature_flags(iam_data_replication: false)
          end

          it 'records no outbox row for the moved application' do
            create(:oauth_application, owner_id: group.id, owner_type: 'Namespace',
              organization: old_organization)

            expect { service.execute }.not_to change { Authn::IamOutbox.count }
          end
        end
      end

      context 'when batching updates' do
        include_context 'with transfer batch size of 1'

        let_it_be_with_refind(:subgroup_project2) do
          create(:project, namespace: subgroup)
        end

        let_it_be_with_refind(:nested_project2) do
          create(:project, namespace: nested_subgroup)
        end

        let_it_be_with_refind(:oauth_app1) do
          create(:oauth_application, owner_id: group.id, owner_type: 'Namespace', organization: old_organization)
        end

        let_it_be_with_refind(:oauth_app2) do
          create(:oauth_application, owner_id: subgroup.id, owner_type: 'Namespace', organization: old_organization)
        end

        let_it_be_with_refind(:oauth_app3) do
          create(:oauth_application, owner_id: nested_subgroup.id, owner_type: 'Namespace',
            organization: old_organization)
        end

        let(:execute_service) { service.execute }
        let(:expected_batch_queries) do
          { 'oauth_applications' => 3 }
        end

        it 'processes all records across multiple batches' do
          service.execute

          expect(subgroup_project2.reload.organization_id).to eq(new_organization.id)
          expect(nested_project2.reload.organization_id).to eq(new_organization.id)
          expect(oauth_app1.reload.organization_id).to eq(new_organization.id)
          expect(oauth_app2.reload.organization_id).to eq(new_organization.id)
          expect(oauth_app3.reload.organization_id).to eq(new_organization.id)
        end

        it_behaves_like 'generates batched transfer queries'
      end

      context 'for burned project routes' do
        it 'updates organization_id for burned routes of transferred projects' do
          burned_route = create(:burned_project_route, :owned_by_project, project: project)

          result = service.execute

          expect(result).to be_success
          expect(burned_route.reload.organization_id).to eq(new_organization.id)
        end

        it 'updates organization_id for burned routes in subgroups' do
          burned_route = create(:burned_project_route, :owned_by_project, project: subgroup_project)

          result = service.execute

          expect(result).to be_success
          expect(burned_route.reload.organization_id).to eq(new_organization.id)
        end

        it 'does not match sibling groups whose path differs only in the escaped character' do
          group.update!(path: 'my_group')
          decoy_group = create(:group, organization: old_organization, path: 'myXgroup')
          decoy_project = create(:project, namespace: decoy_group, organization: old_organization)
          decoy_burn = create(:burned_project_route,
            organization: old_organization,
            path: "#{decoy_group.full_path}/some-project",
            project_id: decoy_project.id
          )

          service.execute

          expect(decoy_burn.reload.organization_id).to eq(old_organization.id)
        end

        it 'matches burned routes case-insensitively against the group path' do
          group.update!(path: 'MixedCase-Group')
          burned_route = create(:burned_project_route,
            organization: old_organization,
            path: "#{group.reload.full_path}/Some-Project",
            project_id: project.id
          )

          service.execute

          expect(burned_route.reload.organization_id).to eq(new_organization.id)
        end

        it 'updates burned routes for deleted projects (tombstones) whose path is under the group' do
          tombstone = create(:burned_project_route,
            organization: old_organization,
            path: "#{group.full_path}/deleted-project",
            project_id: non_existing_record_id
          )

          result = service.execute

          expect(result).to be_success

          expect(tombstone.reload.organization_id).to eq(new_organization.id)
        end

        it 'does not update burned routes whose path is outside the group even if project_id matches' do
          external_burn = create(:burned_project_route,
            organization: old_organization,
            path: 'some-other-namespace/old-project',
            project_id: project.id
          )

          service.execute

          expect(external_burn.reload.organization_id).to eq(old_organization.id)
        end

        it 'does not update burned routes belonging to other groups in the same org' do
          other_group = create(:group, organization: old_organization)
          other_project = create(:project, namespace: other_group, organization: old_organization)
          other_route = create(:burned_project_route, :owned_by_project, project: other_project)

          service.execute

          expect(other_route.reload.organization_id).to eq(old_organization.id)
        end

        it 'does not update burned routes belonging to an unrelated organization' do
          unrelated_organization = create(:organization)
          unrelated_project = create(:project, organization: unrelated_organization)
          unrelated_route = create(:burned_project_route, :owned_by_project, project: unrelated_project)

          service.execute

          expect(unrelated_route.reload.organization_id).to eq(unrelated_organization.id)
        end

        it 'deletes source-org burn and keeps target-org burn when both exist for the same path' do
          path = project.full_path
          old_burn = create(:burned_project_route, organization: old_organization, path: path, project_id: project.id)
          new_burn = create(:burned_project_route, organization: new_organization, path: path, project_id: project.id)

          service.execute

          expect { old_burn.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect(new_burn.reload.organization_id).to eq(new_organization.id)
        end

        context 'when batching burned route transfers' do
          include_context 'with transfer batch size of 1'

          let_it_be(:batch_burned_routes) do
            Array.new(3) do |i|
              create(:burned_project_route,
                organization: old_organization,
                path: "#{group.full_path}/batch-route-#{i}",
                project_id: project.id
              )
            end
          end

          let(:execute_service) { service.execute }
          let(:expected_batch_queries) do
            { 'burned_project_routes' => 3 }
          end

          it 'transfers across multiple batches and removes conflicts' do
            conflicting_old = Array.new(3) do |i|
              p = "#{group.full_path}/conflict-#{i}"
              create(:burned_project_route, organization: old_organization, path: p, project_id: project.id)
            end
            conflicting_new = conflicting_old.map do |route|
              create(:burned_project_route, organization: new_organization, path: route.path, project_id: project.id)
            end

            unique_routes = Array.new(3) do |i|
              create(:burned_project_route,
                organization: old_organization,
                path: "#{group.full_path}/unique-#{i}",
                project_id: project.id
              )
            end

            service.execute

            conflicting_old.each { |r| expect { r.reload }.to raise_error(ActiveRecord::RecordNotFound) }
            conflicting_new.each { |r| expect(r.reload.organization_id).to eq(new_organization.id) }
            unique_routes.each { |r| expect(r.reload.organization_id).to eq(new_organization.id) }
          end

          it_behaves_like 'generates batched transfer queries'
        end
      end

      context 'for agent organization authorizations' do
        it 'updates organization_id for agent authorizations linked to transferred projects' do
          agent = create(:cluster_agent, project: project)
          auth = create(:agent_ci_access_organization_authorization, agent: agent)

          service.execute

          expect(auth.reload.organization_id).to eq(new_organization.id)
        end

        it 'updates organization_id for agent authorizations in subgroups' do
          agent = create(:cluster_agent, project: subgroup_project)
          auth = create(:agent_ci_access_organization_authorization, agent: agent)

          service.execute

          expect(auth.reload.organization_id).to eq(new_organization.id)
        end

        it 'does not update agent authorizations belonging to other projects' do
          other_group = create(:group, organization: old_organization)
          other_project = create(:project, namespace: other_group, organization: old_organization)
          agent = create(:cluster_agent, project: other_project)
          auth = create(:agent_ci_access_organization_authorization, agent: agent)

          service.execute

          expect(auth.reload.organization_id).to eq(old_organization.id)
        end

        it 'does not update agent authorizations belonging to an unrelated organization' do
          unrelated_organization = create(:organization)
          unrelated_project = create(:project, organization: unrelated_organization)
          agent = create(:cluster_agent, project: unrelated_project)
          auth = create(:agent_ci_access_organization_authorization, agent: agent)

          service.execute

          expect(auth.reload.organization_id).to eq(unrelated_organization.id)
        end

        context 'when batching updates' do
          include_context 'with transfer batch size of 1'

          let_it_be(:batch_agent_auths) do
            Array.new(3) do
              agent = create(:cluster_agent, project: project)
              create(:agent_ci_access_organization_authorization, agent: agent)
            end
          end

          let(:execute_service) { service.execute }
          let(:expected_batch_queries) do
            { 'agent_organization_authorizations' => 3 }
          end

          it 'processes all records across multiple batches' do
            service.execute

            batch_agent_auths.each { |a| expect(a.reload.organization_id).to eq(new_organization.id) }
          end

          it_behaves_like 'generates batched transfer queries'
        end
      end

      context 'when transferring topics' do
        let!(:old_topic) { create(:topic, name: 'rails', organization: old_organization) }
        let!(:project_topic) { create(:project_topic, project: project, topic: old_topic) }

        it 'delegates to TopicsService' do
          service.execute

          new_topic = Projects::Topic.find_by(organization_id: new_organization.id, name: 'rails')
          expect(new_topic).to be_present
          expect(project_topic.reload.topic_id).to eq(new_topic.id)
        end

        context 'when topic has an avatar' do
          let!(:old_topic) do
            create(:topic, :with_avatar, organization: old_organization, slug: 'avatar-topic')
          end

          let!(:project_topic) do
            create(:project_topic, project: project, topic: old_topic)
          end

          it 'enqueues Organizations::TransferTopicAvatarWorker' do
            expect { service.execute }.to change { Organizations::TransferTopicAvatarWorker.jobs.size }.by(1)
          end

          it 'does not enqueue the worker when the transfer fails' do
            # Raised from the last step inside the transaction, so anything scheduled
            # before it would already have been enqueued.
            allow(service).to receive(:publish_event).and_raise(StandardError, 'Transfer failed')

            expect(Organizations::TransferTopicAvatarWorker).not_to receive(:perform_async)

            expect(service.execute).to be_error
          end
        end
      end

      context 'for slack api scope transfers' do
        let_it_be(:slack_scope) do
          create(:slack_integration, :group, :all_features_supported, group: group)
            .slack_api_scopes.first
        end

        let_it_be(:slack_integration) { SlackIntegration.find_by(group_id: group.id) }

        it 'duplicates scope records into the new org and repoints the join table' do
          old_scope_id = slack_scope.id
          old_scope_name = slack_scope.name

          service.execute

          new_scope = Integrations::SlackWorkspace::ApiScope.find_by(
            organization_id: new_organization.id, name: old_scope_name
          )

          expect(new_scope).to be_present
          expect(new_scope.id).not_to eq(old_scope_id)

          repointed_ids = slack_integration.reload.slack_integrations_scopes.pluck(:slack_api_scope_id)
          expect(repointed_ids).to all(satisfy { |id|
            Integrations::SlackWorkspace::ApiScope.find(id).organization_id == new_organization.id
          })
        end

        it 'does not modify the original scope record' do
          expect { service.execute }.not_to change { slack_scope.reload.organization_id }
        end

        context 'when matching scopes already exist in the new org' do
          before do
            scope_names = slack_integration.slack_api_scopes.pluck(:name)
            Integrations::SlackWorkspace::ApiScope.find_or_initialize_by_names(
              scope_names, organization_id: new_organization.id
            )
          end

          it 'repoints to existing scopes without creating duplicates' do
            expect { service.execute }.not_to change {
              Integrations::SlackWorkspace::ApiScope.where(organization_id: new_organization.id).count
            }
          end
        end

        context 'when scope is referenced by a project integration' do
          let_it_be(:project_slack) do
            create(:slack_integration, :project, :all_features_supported,
              project: create(:project, namespace: group, organization: old_organization)
            )
          end

          it 'repoints project-level scopes to the new org' do
            service.execute

            repointed_ids = project_slack.reload.slack_integrations_scopes.pluck(:slack_api_scope_id)
            expect(repointed_ids).to all(satisfy { |id|
              Integrations::SlackWorkspace::ApiScope.find(id).organization_id == new_organization.id
            })
          end
        end

        context 'when multiple scopes are transferred' do
          let_it_be(:second_slack_integration) do
            create(:slack_integration, :group, :all_features_supported,
              group: create(:group, parent: group, organization: old_organization)
            )
          end

          it 'repoints all scope references across multiple integrations' do
            all_old_scope_ids = (slack_integration.slack_integrations_scopes.pluck(:slack_api_scope_id) +
              second_slack_integration.slack_integrations_scopes.pluck(:slack_api_scope_id)).uniq

            service.execute

            [slack_integration, second_slack_integration].each do |si|
              repointed_ids = si.reload.slack_integrations_scopes.pluck(:slack_api_scope_id)

              expect(repointed_ids).to all(satisfy { |id|
                Integrations::SlackWorkspace::ApiScope.find(id).organization_id == new_organization.id
              })
            end

            new_scope_names = Integrations::SlackWorkspace::ApiScope
              .where(organization_id: new_organization.id)
              .pluck(:name)

            old_scope_names = Integrations::SlackWorkspace::ApiScope
              .where(id: all_old_scope_ids)
              .pluck(:name)

            expect(new_scope_names).to match_array(old_scope_names)
          end
        end

        context 'when scope is referenced by a group outside the transfer' do
          let_it_be(:other_group) { create(:group, organization: old_organization) }
          let_it_be(:other_slack) do
            create(:slack_integration, :group, :all_features_supported, group: other_group)
          end

          it 'does not repoint scopes outside the transferred hierarchy' do
            service.execute

            repointed_ids = other_slack.reload.slack_integrations_scopes.pluck(:slack_api_scope_id)

            expect(repointed_ids).to all(satisfy { |id|
              Integrations::SlackWorkspace::ApiScope.find(id).organization_id == old_organization.id
            })
          end
        end
      end

      context 'for user agent details' do
        it 'enqueues TransferUserAgentDetailsWorker with correct arguments' do
          expect(Organizations::TransferUserAgentDetailsWorker).to receive(:perform_async).with(
            group.id, old_organization.id, new_organization.id
          )

          service.execute
        end

        it 'does not move the rows inside the transaction' do
          detail = create(:user_agent_detail,
            subject: create(:issue, project: nested_project), organization: old_organization)

          expect { service.execute }.not_to change { detail.reload.organization_id }
        end

        it 'does not enqueue the worker when the transfer fails' do
          allow(service).to receive(:publish_event).and_raise(StandardError, 'Transfer failed')

          expect(Organizations::TransferUserAgentDetailsWorker).not_to receive(:perform_async)

          expect(service.execute).to be_error
        end

        # Organizations::ActivateService wraps this service in its own transaction and
        # rolls it back when a later step fails.
        it 'does not enqueue the worker when a wrapping transaction rolls back' do
          expect(Organizations::TransferUserAgentDetailsWorker).not_to receive(:perform_async)

          ApplicationRecord.transaction do
            expect(service.execute).to be_success

            raise ActiveRecord::Rollback
          end
        end
      end
    end

    context 'when group is not root' do
      let_it_be(:parent_group) { create(:group, organization: old_organization) }
      let_it_be_with_refind(:subgroup) { create(:group, parent: parent_group, organization: old_organization) }
      let(:service) { described_class.new(group: subgroup, new_organization: new_organization, current_user: user) }

      it 'returns error ServiceResponse' do
        result = service.execute

        expect(result).to be_error
        expect(result.reason).to eq(:group_not_root)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message:
              s_('TransferOrganization|Only top-level groups can be transferred to a different organization.')
          )
        )
      end

      it 'does not update organization_id' do
        original_organization_id = subgroup.organization_id

        service.execute

        expect(subgroup.reload.organization_id).to eq(original_organization_id)
      end
    end

    context 'when group is already in the target organization' do
      let_it_be(:group_in_new_org) { create(:group, organization: new_organization, owners: user) }
      let(:service) do
        described_class.new(group: group_in_new_org, new_organization: new_organization, current_user: user)
      end

      it 'returns error ServiceResponse' do
        result = service.execute

        expect(result).to be_error
        expect(result.reason).to eq(:already_transferred)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message: s_('TransferOrganization|Group is already in the target organization.')
          )
        )
      end

      it 'does not update organization_id' do
        expect { service.execute }.not_to change { group_in_new_org.reload.organization_id }
      end

      it 'does not enqueue TransferOrganizationWorker' do
        expect(Ci::Runners::TransferOrganizationWorker).not_to receive(:perform_async)

        service.execute
      end
    end

    context 'when top-level group is at the target but descendants are not' do
      # Simulates the activation flow: Organizations::ConfirmService has
      # moved the top-level group's organization_id, but the descendants
      # and their projects still belong to the previous organization.
      let_it_be_with_refind(:top_level) { create(:group, organization: old_organization, owners: user) }
      let_it_be_with_refind(:subgroup) { create(:group, parent: top_level, organization: old_organization) }
      let_it_be_with_refind(:nested_project) do
        create(:project, namespace: subgroup, organization: old_organization)
      end

      let(:service) do
        described_class.new(group: top_level, new_organization: new_organization, current_user: user)
      end

      before do
        # Mimic Organizations::ConfirmService having moved only the top-level
        # group's organization_id forward, without touching descendants.
        top_level.update_column(:organization_id, new_organization.id)
      end

      it 'transfers the descendants to the new organization' do
        expect(service.execute).to be_success

        expect(subgroup.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.project_namespace.reload.organization_id).to eq(new_organization.id)
      end

      it 'publishes GroupTransferredEvent with the descendants source organization' do
        expect { service.execute }.to publish_event(Organizations::GroupTransferredEvent).with(
          group_id: top_level.id,
          old_organization_id: old_organization.id,
          new_organization_id: new_organization.id
        )
      end

      it 'enqueues TransferOrganizationWorker with the descendants source organization' do
        expect(Ci::Runners::TransferOrganizationWorker).to receive(:perform_async)
          .with(top_level.id, old_organization.id, new_organization.id)

        service.execute
      end
    end

    context 'when user lacks permissions' do
      context 'when user is not group owner' do
        let_it_be(:non_group_owner) { create(:user, organization: old_organization) }
        let(:service) do
          described_class.new(group: group, new_organization: new_organization, current_user: non_group_owner)
        end

        before_all do
          new_organization.add_owner(non_group_owner)
        end

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(
            format(
              s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
              error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
          )
        end

        it 'does not update organization_id' do
          original_organization_id = group.organization_id

          service.execute

          expect(group.reload.organization_id).to eq(original_organization_id)
        end
      end

      context 'when user is not organization owner' do
        let_it_be(:non_org_owner) { create(:user, organization: old_organization) }
        let(:service) do
          described_class.new(group: group, new_organization: new_organization, current_user: non_org_owner)
        end

        before_all do
          group.add_owner(non_org_owner)
        end

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(
            format(
              s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
              error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
          )
        end

        it 'does not update organization_id' do
          original_organization_id = group.organization_id

          service.execute

          expect(group.reload.organization_id).to eq(original_organization_id)
        end
      end

      context 'when user is neither group nor organization owner' do
        let_it_be(:non_owner) { create(:user, organization: old_organization) }
        let(:service) do
          described_class.new(group: group, new_organization: new_organization, current_user: non_owner)
        end

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(
            format(
              s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
              error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
          )
        end

        it 'does not update organization_id' do
          original_organization_id = group.organization_id

          service.execute

          expect(group.reload.organization_id).to eq(original_organization_id)
        end
      end

      context 'when user is an admin without admin mode' do
        let_it_be(:admin_user) { create(:admin) }

        let(:service) do
          described_class.new(group: group, new_organization: new_organization, current_user: admin_user)
        end

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(
            format(
              s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
              error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
          )
        end

        it 'does not update organization_id' do
          original_organization_id = group.organization_id

          service.execute

          expect(group.reload.organization_id).to eq(original_organization_id)
        end
      end
    end

    context 'when user is admin with admin mode enabled', :enable_admin_mode do
      let_it_be(:admin_user) { create(:admin) }

      let(:service) do
        described_class.new(group: group, new_organization: new_organization, current_user: admin_user)
      end

      it 'allows transfer' do
        result = service.execute

        expect(result).to be_success
        expect(group.reload.organization_id).to eq(new_organization.id)
      end
    end

    context 'with nil new_organization' do
      let(:service) { described_class.new(group: group, new_organization: nil, current_user: user) }

      it 'returns error ServiceResponse' do
        result = service.execute

        expect(result).to be_error
        expect(result.reason).to eq(:missing_permission)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
          )
        )
      end

      it 'does not update organization_id' do
        original_organization_id = group.organization_id

        service.execute

        expect(group.reload.organization_id).to eq(original_organization_id)
      end
    end

    context 'when an exception occurs during transfer' do
      let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
      let_it_be_with_refind(:nested_subgroup) { create(:group, parent: subgroup, organization: old_organization) }
      let_it_be_with_refind(:project) { create(:project, namespace: group, organization: old_organization) }
      let_it_be_with_refind(:subgroup_project) do
        create(:project, namespace: subgroup, organization: old_organization)
      end

      let_it_be_with_refind(:nested_project) do
        create(:project, namespace: nested_subgroup, organization: old_organization)
      end

      let(:error_message) { 'Transfer failed' }

      before do
        allow(ForkNetwork).to receive(:where).and_raise(StandardError, error_message)
      end

      it 'returns error ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq(error_message)
      end

      it 'logs transfer error with correct payload' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: "Group was not transferred to a new organization",
            group_path: group.full_path,
            group_id: group.id,
            new_organization_path: new_organization.full_path,
            new_organization_id: new_organization.id,
            error_message: error_message
          )
        )

        service.execute
      end

      it_behaves_like 'rolls back organization_id updates' do
        let(:records) do
          [
            group, subgroup, nested_subgroup,
            project, subgroup_project, nested_project,
            project.project_namespace, subgroup_project.project_namespace, nested_project.project_namespace
          ]
        end
      end

      context "with runner records" do
        let_it_be(:ci_tag) { create(:ci_tag, name: "rollback-tag") }
        let_it_be_with_refind(:group_runner) do
          create(:ci_runner, :online, runner_type: :group_type, groups: [group])
        end

        let_it_be_with_refind(:group_runner_manager) do
          create(:ci_runner_machine, runner: group_runner)
        end

        let_it_be_with_refind(:group_runner_tagging) do
          create(:ci_runner_tagging, runner: group_runner, tag: ci_tag)
        end

        let_it_be_with_refind(:project_runner) do
          create(:ci_runner, :online, runner_type: :project_type, projects: [project])
        end

        let_it_be_with_refind(:project_runner_manager) do
          create(:ci_runner_machine, runner: project_runner)
        end

        let_it_be_with_refind(:project_runner_tagging) do
          create(:ci_runner_tagging, runner: project_runner, tag: ci_tag)
        end

        it_behaves_like "rolls back organization_id updates" do
          let(:records) do
            [
              group_runner, group_runner_manager, group_runner_tagging,
              project_runner, project_runner_manager, project_runner_tagging
            ]
          end
        end
      end

      context "with fork network records" do
        let_it_be_with_refind(:fork_network) do
          create(:fork_network, root_project: project)
        end

        it_behaves_like "rolls back organization_id updates" do
          let(:records) { [fork_network] }
        end
      end

      context 'with slack api scope duplication' do
        let_it_be(:slack_integration) do
          create(:slack_integration, :group, :all_features_supported, group: group)
        end

        it 'rolls back duplicated scopes and repointed join table rows' do
          original_scope_ids = slack_integration.slack_integrations_scopes.pluck(:slack_api_scope_id)

          expect { service.execute }.not_to change {
            Integrations::SlackWorkspace::ApiScope.where(organization_id: new_organization.id).count
          }

          expect(slack_integration.reload.slack_integrations_scopes.pluck(:slack_api_scope_id))
            .to match_array(original_scope_ids)
        end
      end

      context "with visibility level changes that would have been made" do
        let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PRIVATE, owners: user) }
        let_it_be_with_refind(:public_subgroup) do
          create(:group, :public, parent: group, organization: old_organization)
        end

        let_it_be_with_refind(:public_project) do
          create(:project, :public, namespace: group, organization: old_organization)
        end

        it 'rolls back visibility level changes for groups due to transaction failure' do
          expect { service.execute }.not_to change { public_subgroup.reload.visibility_level }
        end

        it 'rolls back visibility level changes for projects due to transaction failure' do
          expect { service.execute }.not_to change { public_project.reload.visibility_level }
        end

        it 'rolls back visibility level changes for project namespaces due to transaction failure' do
          expect { service.execute }.not_to change { public_project.project_namespace.reload.visibility_level }
        end
      end

      it 'does not enqueue TransferOrganizationWorker' do
        expect(Ci::Runners::TransferOrganizationWorker).not_to receive(:perform_async)

        service.execute
      end

      it 'does not publish a GroupTransferredEvent' do
        expect { service.execute }.not_to publish_event(Organizations::GroupTransferredEvent)
      end

      context 'when a project is linked to a pool repository' do
        let_it_be_with_reload(:pooled_project) do
          create(:project, namespace: group, organization: old_organization)
        end

        let_it_be(:pool_repository) { create(:pool_repository, source_project: pooled_project) }

        # Disconnecting is scheduled before ForkNetwork raises, so this only holds
        # while the enqueue is deferred past the commit.
        it 'does not enqueue Repositories::LeavePoolRepositoryWorker' do
          expect(Repositories::LeavePoolRepositoryWorker).not_to receive(:perform_async)

          expect(service.execute).to be_error
        end
      end
    end

    context 'when transferring fork networks' do
      let_it_be_with_refind(:project_with_fork_network) do
        create(:project, namespace: group, organization: old_organization)
      end

      let_it_be_with_refind(:fork_network) do
        create(:fork_network, root_project: project_with_fork_network)
      end

      it 'updates fork_network organization_id when root_project is in transferred group' do
        expect { service.execute }.to change { fork_network.reload.organization_id }
          .from(old_organization.id).to(new_organization.id)
      end

      it 'keeps fork_network valid after transfer' do
        service.execute

        expect(fork_network.reload).to be_valid
      end

      context 'when fork network root_project is in a subgroup' do
        let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
        let_it_be_with_refind(:subgroup_project) do
          create(:project, namespace: subgroup, organization: old_organization)
        end

        let_it_be_with_refind(:subgroup_fork_network) do
          create(:fork_network, root_project: subgroup_project)
        end

        it 'updates fork_network organization_id for projects in subgroups' do
          expect { service.execute }.to change { subgroup_fork_network.reload.organization_id }
            .from(old_organization.id).to(new_organization.id)
        end
      end

      context 'when fork network root_project is NOT in the transferred group' do
        let_it_be(:other_group) { create(:group, organization: old_organization) }
        let_it_be_with_refind(:other_project) do
          create(:project, namespace: other_group, organization: old_organization)
        end

        let_it_be_with_refind(:other_fork_network) do
          create(:fork_network, root_project: other_project)
        end

        it 'does not update fork_network organization_id' do
          expect { service.execute }.not_to change { other_fork_network.reload.organization_id }
        end
      end

      context 'when no projects have fork networks' do
        let_it_be_with_refind(:project_without_fork_network) do
          create(:project, namespace: group, organization: old_organization)
        end

        before do
          ForkNetwork.delete_all
        end

        it 'completes transfer successfully' do
          expect { service.execute }.not_to raise_error
          expect(group.reload.organization_id).to eq(new_organization.id)
          expect(project_without_fork_network.reload.organization_id).to eq(new_organization.id)
        end
      end
    end

    context 'when disconnecting from gitaly' do
      let_it_be_with_reload(:project) do
        create(:project, :small_repo, namespace: group, organization: old_organization)
      end

      context 'when linked to pool repository' do
        let_it_be_with_reload(:pool_repository) do
          create(:pool_repository, :ready, source_project: project)
        end

        it 'enqueues Repositories::LeavePoolRepositoryWorker' do
          expect { service.execute }.to change { Repositories::LeavePoolRepositoryWorker.jobs.size }.by(1)
        end
      end

      context 'when not linked to pool repository' do
        before do
          project.update!(pool_repository: nil)
        end

        it 'does not enqueue Repositories::LeavePoolRepositoryWorker' do
          service.execute
          expect(Repositories::LeavePoolRepositoryWorker.jobs.size).to eq(0)
        end
      end
    end
  end

  describe '#async_execute' do
    context 'when transfer is allowed' do
      it 'enqueues the transfer worker' do
        expect(Organizations::Groups::TransferWorker).to receive(:perform_async).with(
          {
            'group_id' => group.id,
            'organization_id' => new_organization.id,
            'current_user_id' => user.id
          }
        )

        result = service.async_execute

        expect(result).to be_success
        expect(result.message).to include('initiated')
      end
    end

    context 'when group is not root' do
      let_it_be(:parent_group) { create(:group, organization: old_organization) }
      let_it_be(:subgroup_user) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:subgroup) do
        create(:group, parent: parent_group, organization: old_organization, developers: subgroup_user)
      end

      let(:service) { described_class.new(group: subgroup, new_organization: new_organization, current_user: user) }

      it 'returns error ServiceResponse' do
        result = service.async_execute

        expect(result).to be_error
        expect(result.reason).to eq(:group_not_root)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message:
              s_('TransferOrganization|Only top-level groups can be transferred to a different organization.')
          )
        )
      end

      it 'does not enqueue the worker' do
        expect(Organizations::Groups::TransferWorker).not_to receive(:perform_async)

        service.async_execute
      end
    end

    context 'when user lacks permissions' do
      let_it_be(:non_owner_user) { create(:user, organization: old_organization) }
      let(:service) do
        described_class.new(group: group, new_organization: new_organization, current_user: non_owner_user)
      end

      it 'returns error ServiceResponse' do
        result = service.async_execute

        expect(result).to be_error
        expect(result.reason).to eq(:missing_permission)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
          )
        )
      end

      it 'does not enqueue the worker' do
        expect(Organizations::Groups::TransferWorker).not_to receive(:perform_async)

        service.async_execute
      end
    end
  end
end
