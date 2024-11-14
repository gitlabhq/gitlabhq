# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateSharedRunnersService, '#execute', :sidekiq_inline, feature_category: :groups_and_projects do
  include ReloadHelpers

  let(:params) { {} }
  let(:service) { described_class.new(group, user, params) }

  subject(:execute) { service.execute }

  context 'when current_user is not the group owner' do
    let_it_be(:user) { create(:user) }

    let(:group) { create(:group, maintainers: user) }
    let(:params) { { shared_runners_setting: 'enabled' } }

    it 'returns error' do
      is_expected.to match(a_hash_including(
        status: :error,
        message: 'Operation not allowed',
        http_status: 403))
    end
  end

  context 'when current_user is the group owner' do
    let_it_be(:user) { create(:user) }

    before do
      group.add_owner(user)
    end

    context 'enable shared Runners' do
      let(:params) { { shared_runners_setting: 'enabled' } }

      context 'when ancestor disable shared runners' do
        let(:parent) { create(:group, :shared_runners_disabled) }
        let(:group) { create(:group, :shared_runners_disabled, parent: parent) }
        let!(:project) { create(:project, shared_runners_enabled: false, group: group) }

        it 'returns an error and does not enable shared runners' do
          expect do
            expect(execute).to match(a_hash_including(
              status: :error,
              message:
                'Validation failed: Shared runners enabled cannot be enabled because parent group ' \
                'has shared Runners disabled'))

            reload_models(parent, group, project)
          end.to not_change { parent.shared_runners_enabled }
            .and not_change { group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end

      context 'when updating root group' do
        let(:group) { create(:group, :shared_runners_disabled) }
        let(:sub_group) { create(:group, :shared_runners_disabled, parent: group) }
        let!(:project) { create(:project, shared_runners_enabled: false, group: sub_group) }

        it 'enables shared Runners for itself and descendants' do
          expect do
            expect(execute[:status]).to eq(:success)

            reload_models(group, sub_group, project)
          end.to change { group.shared_runners_enabled }.from(false).to(true)
            .and change { sub_group.shared_runners_enabled }.from(false).to(true)
            .and change { project.shared_runners_enabled }.from(false).to(true)
        end

        context 'when already allowing descendants to override' do
          let(:group) { create(:group, :shared_runners_disabled_and_overridable) }

          it 'enables shared Runners for itself and descendants' do
            expect do
              expect(execute[:status]).to eq(:success)

              reload_models(group, sub_group, project)
            end.to change { group.shared_runners_enabled }.from(false).to(true)
              .and change { group.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
              .and change { sub_group.shared_runners_enabled }.from(false).to(true)
              .and change { project.shared_runners_enabled }.from(false).to(true)
          end
        end
      end

      context 'when group has pending builds', :aggregate_failures do
        let_it_be(:group) { create(:group, :shared_runners_disabled) }
        let_it_be(:sub_group) { create(:group, :shared_runners_disabled, parent: group) }
        let_it_be(:project) { create(:project, namespace: group, shared_runners_enabled: false) }
        let_it_be(:project2) { create(:project, namespace: sub_group, shared_runners_enabled: false) }
        let_it_be(:pending_build_1) { create(:ci_pending_build, project: project, instance_runners_enabled: false) }
        let_it_be(:pending_build_2) { create(:ci_pending_build, project: project, instance_runners_enabled: false) }
        let_it_be(:pending_build_3) { create(:ci_pending_build, project: project2, instance_runners_enabled: false) }

        it 'updates pending builds for the group and descendants' do
          expect(::Ci::PendingBuilds::UpdateGroupWorker).to receive(:perform_async)
            .with(group.id, { 'instance_runners_enabled' => true })
            .and_call_original

          execute

          expect(pending_build_1.reload.instance_runners_enabled).to be_truthy
          expect(pending_build_2.reload.instance_runners_enabled).to be_truthy
          expect(pending_build_3.reload.instance_runners_enabled).to be_truthy
        end

        context 'when shared runners is not toggled' do
          let(:params) { { shared_runners_setting: 'invalid_enabled' } }

          it 'does not update pending builds for the group' do
            expect(::Ci::PendingBuilds::UpdateGroupWorker).not_to receive(:new)

            execute

            expect(pending_build_1.reload.instance_runners_enabled).to be_falsey
            expect(pending_build_2.reload.instance_runners_enabled).to be_falsey
          end
        end
      end
    end

    context 'disable shared Runners' do
      let!(:group) { create(:group) }
      let!(:sub_group) { create(:group, :shared_runners_disabled_and_overridable, parent: group) }
      let!(:sub_group2) { create(:group, parent: group) }
      let!(:project) { create(:project, group: group, shared_runners_enabled: true) }
      let!(:project2) { create(:project, group: sub_group2, shared_runners_enabled: true) }

      let(:params) { { shared_runners_setting: Namespace::SR_DISABLED_AND_UNOVERRIDABLE } }

      it 'disables shared Runners for all descendant groups and projects' do
        expect do
          expect(execute[:status]).to eq(:success)

          reload_models(group, sub_group, sub_group2, project, project2)
        end.to change { group.shared_runners_enabled }.from(true).to(false)
          .and not_change { group.allow_descendants_override_disabled_shared_runners }
          .and not_change { sub_group.shared_runners_enabled }
          .and change { sub_group.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
          .and change { sub_group2.shared_runners_enabled }.from(true).to(false)
          .and not_change { sub_group2.allow_descendants_override_disabled_shared_runners }
          .and change { project.shared_runners_enabled }.from(true).to(false)
          .and change { project2.shared_runners_enabled }.from(true).to(false)
      end

      context 'with override on self' do
        let(:group) { create(:group, :shared_runners_disabled_and_overridable) }

        it 'disables it' do
          expect do
            expect(execute[:status]).to eq(:success)

            group.reload
          end
            .to not_change { group.shared_runners_enabled }
            .and change { group.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
        end
      end

      context 'when group has pending builds', :aggregate_failures do
        let!(:pending_build_1) { create(:ci_pending_build, project: project, instance_runners_enabled: true) }
        let!(:pending_build_2) { create(:ci_pending_build, project: project, instance_runners_enabled: true) }

        it 'updates pending builds for the group and descendants' do
          expect(::Ci::PendingBuilds::UpdateGroupWorker).to receive(:perform_async)
            .with(group.id, { 'instance_runners_enabled' => false })
            .and_call_original

          execute

          expect(pending_build_1.reload.instance_runners_enabled).to be_falsey
          expect(pending_build_2.reload.instance_runners_enabled).to be_falsey
        end
      end
    end

    shared_examples 'allow descendants to override' do
      context 'top level group' do
        let!(:group) { create(:group, :shared_runners_disabled) }
        let!(:sub_group) { create(:group, :shared_runners_disabled, parent: group) }
        let!(:project) { create(:project, shared_runners_enabled: false, group: sub_group) }

        it 'enables allow descendants to override only for itself' do
          expect do
            expect(execute[:status]).to eq(:success)

            reload_models(group, sub_group, project)
          end.to change { group.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
            .and not_change { group.shared_runners_enabled }
            .and not_change { sub_group.allow_descendants_override_disabled_shared_runners }
            .and not_change { sub_group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end

      context 'when ancestor disables shared Runners but allows to override' do
        let!(:parent) { create(:group, :shared_runners_disabled_and_overridable) }
        let!(:group) { create(:group, :shared_runners_disabled, parent: parent) }
        let!(:project) { create(:project, shared_runners_enabled: false, group: group) }

        it 'enables allow descendants to override' do
          expect do
            expect(execute[:status]).to eq(:success)

            reload_models(parent, group, project)
          end
            .to not_change { parent.allow_descendants_override_disabled_shared_runners }
            .and not_change { parent.shared_runners_enabled }
            .and change { group.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
            .and not_change { group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end

      context 'when ancestor disables shared runners' do
        let(:parent) { create(:group, :shared_runners_disabled) }
        let(:group) { create(:group, :shared_runners_disabled, parent: parent) }
        let!(:project) { create(:project, shared_runners_enabled: false, group: group) }

        it 'returns an error and does not enable shared runners' do
          expect do
            expect(execute).to match(a_hash_including(
              status: :error,
              message:
                'Validation failed: Allow descendants override disabled shared runners cannot be enabled ' \
                'because parent group does not allow it'))

            reload_models(parent, group, project)
          end.to not_change { parent.shared_runners_enabled }
            .and not_change { group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end

      context 'top level group that has shared Runners enabled' do
        let!(:group) { create(:group, shared_runners_enabled: true) }
        let!(:sub_group) { create(:group, shared_runners_enabled: true, parent: group) }
        let!(:project) { create(:project, shared_runners_enabled: true, group: sub_group) }

        it 'enables allow descendants to override & disables shared runners everywhere' do
          expect do
            expect(execute[:status]).to eq(:success)

            reload_models(group, sub_group, project)
          end
            .to change { group.shared_runners_enabled }.from(true).to(false)
            .and change { group.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
            .and change { sub_group.shared_runners_enabled }.from(true).to(false)
            .and change { project.shared_runners_enabled }.from(true).to(false)
        end
      end
    end

    context "when using SR_DISABLED_AND_OVERRIDABLE" do
      let(:params) { { shared_runners_setting: Namespace::SR_DISABLED_AND_OVERRIDABLE } }

      include_examples 'allow descendants to override'
    end
  end
end
