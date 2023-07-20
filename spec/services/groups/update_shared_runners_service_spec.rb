# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateSharedRunnersService, feature_category: :groups_and_projects do
  include ReloadHelpers

  let(:user) { create(:user) }
  let(:params) { {} }
  let(:service) { described_class.new(group, user, params) }

  describe '#execute' do
    subject { service.execute }

    context 'when current_user is not the group owner' do
      let(:group) { create(:group) }

      let(:params) { { shared_runners_setting: 'enabled' } }

      before do
        group.add_maintainer(user)
      end

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq('Operation not allowed')
        expect(subject[:http_status]).to eq(403)
      end
    end

    context 'when current_user is the group owner' do
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
              expect(subject[:status]).to eq(:error)
              expect(subject[:message]).to eq('Validation failed: Shared runners enabled cannot be enabled because parent group has shared Runners disabled')

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
              expect(subject[:status]).to eq(:success)

              reload_models(group, sub_group, project)
            end.to change { group.shared_runners_enabled }.from(false).to(true)
              .and change { sub_group.shared_runners_enabled }.from(false).to(true)
              .and change { project.shared_runners_enabled }.from(false).to(true)
          end

          context 'when already allowing descendants to override' do
            let(:group) { create(:group, :shared_runners_disabled_and_overridable) }

            it 'enables shared Runners for itself and descendants' do
              expect do
                expect(subject[:status]).to eq(:success)

                reload_models(group, sub_group, project)
              end.to change { group.shared_runners_enabled }.from(false).to(true)
                .and change { group.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
                .and change { sub_group.shared_runners_enabled }.from(false).to(true)
                .and change { project.shared_runners_enabled }.from(false).to(true)
            end
          end
        end

        context 'when group has pending builds' do
          let_it_be(:group) { create(:group, :shared_runners_disabled) }
          let_it_be(:project) { create(:project, namespace: group, shared_runners_enabled: false) }
          let_it_be(:pending_build_1) { create(:ci_pending_build, project: project, instance_runners_enabled: false) }
          let_it_be(:pending_build_2) { create(:ci_pending_build, project: project, instance_runners_enabled: false) }

          it 'updates pending builds for the group' do
            expect(::Ci::UpdatePendingBuildService).to receive(:new).and_call_original

            subject

            expect(pending_build_1.reload.instance_runners_enabled).to be_truthy
            expect(pending_build_2.reload.instance_runners_enabled).to be_truthy
          end

          context 'when shared runners is not toggled' do
            let(:params) { { shared_runners_setting: 'invalid_enabled' } }

            it 'does not update pending builds for the group' do
              expect(::Ci::UpdatePendingBuildService).not_to receive(:new)

              subject

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
            expect(subject[:status]).to eq(:success)

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
              expect(subject[:status]).to eq(:success)

              group.reload
            end
              .to not_change { group.shared_runners_enabled }
              .and change { group.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
          end
        end

        context 'when group has pending builds' do
          let!(:pending_build_1) { create(:ci_pending_build, project: project, instance_runners_enabled: true) }
          let!(:pending_build_2) { create(:ci_pending_build, project: project, instance_runners_enabled: true) }

          it 'updates pending builds for the group' do
            expect(::Ci::UpdatePendingBuildService).to receive(:new).and_call_original

            subject

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
              expect(subject[:status]).to eq(:success)

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
              expect(subject[:status]).to eq(:success)

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
              expect(subject[:status]).to eq(:error)
              expect(subject[:message]).to eq('Validation failed: Allow descendants override disabled shared runners cannot be enabled because parent group does not allow it')

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
              expect(subject[:status]).to eq(:success)

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

      context "when using SR_DISABLED_WITH_OVERRIDE" do
        let(:params) { { shared_runners_setting: Namespace::SR_DISABLED_WITH_OVERRIDE } }

        include_examples 'allow descendants to override'
      end
    end
  end
end
