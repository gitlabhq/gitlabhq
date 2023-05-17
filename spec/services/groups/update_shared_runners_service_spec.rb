# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateSharedRunnersService, feature_category: :subgroups do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:params) { {} }

  describe '#execute' do
    subject { described_class.new(group, user, params).execute }

    context 'when current_user is not the group owner' do
      let_it_be(:group) { create(:group) }

      let(:params) { { shared_runners_setting: 'enabled' } }

      before do
        group.add_maintainer(user)
      end

      it 'results error and does not call any method' do
        expect(group).not_to receive(:update_shared_runners_setting!)

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

        context 'group that its ancestors have shared runners disabled' do
          let_it_be(:parent) { create(:group, :shared_runners_disabled) }
          let_it_be(:group) { create(:group, :shared_runners_disabled, parent: parent) }

          it 'results error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq('Validation failed: Shared runners enabled cannot be enabled because parent group has shared Runners disabled')
          end
        end

        context 'root group with shared runners disabled' do
          let_it_be(:group) { create(:group, :shared_runners_disabled) }

          it 'receives correct method and succeeds' do
            expect(group).to receive(:update_shared_runners_setting!).with('enabled')

            expect(subject[:status]).to eq(:success)
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
              expect(::Ci::UpdatePendingBuildService).not_to receive(:new).and_call_original

              subject

              expect(pending_build_1.reload.instance_runners_enabled).to be_falsey
              expect(pending_build_2.reload.instance_runners_enabled).to be_falsey
            end
          end
        end
      end

      context 'disable shared Runners' do
        let_it_be(:group) { create(:group) }

        let(:params) { { shared_runners_setting: Namespace::SR_DISABLED_AND_UNOVERRIDABLE } }

        it 'receives correct method and succeeds' do
          expect(group).to receive(:update_shared_runners_setting!).with(Namespace::SR_DISABLED_AND_UNOVERRIDABLE)

          expect(subject[:status]).to eq(:success)
        end

        context 'when group has pending builds' do
          let_it_be(:project) { create(:project, namespace: group) }
          let_it_be(:pending_build_1) { create(:ci_pending_build, project: project, instance_runners_enabled: true) }
          let_it_be(:pending_build_2) { create(:ci_pending_build, project: project, instance_runners_enabled: true) }

          it 'updates pending builds for the group' do
            expect(::Ci::UpdatePendingBuildService).to receive(:new).and_call_original

            subject

            expect(pending_build_1.reload.instance_runners_enabled).to be_falsey
            expect(pending_build_2.reload.instance_runners_enabled).to be_falsey
          end
        end
      end

      context 'allow descendants to override' do
        let(:params) { { shared_runners_setting: Namespace::SR_DISABLED_AND_OVERRIDABLE } }

        context 'top level group' do
          let_it_be(:group) { create(:group, :shared_runners_disabled) }

          it 'receives correct method and succeeds' do
            expect(group).to receive(:update_shared_runners_setting!).with(Namespace::SR_DISABLED_AND_OVERRIDABLE)

            expect(subject[:status]).to eq(:success)
          end
        end

        context 'when parent does not allow' do
          let_it_be(:parent) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false) }
          let_it_be(:group) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false, parent: parent) }

          it 'results error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq('Validation failed: Allow descendants override disabled shared runners cannot be enabled because parent group does not allow it')
          end
        end

        context 'when using DISABLED_WITH_OVERRIDE (deprecated)' do
          let(:params) { { shared_runners_setting: Namespace::SR_DISABLED_WITH_OVERRIDE } }

          context 'top level group' do
            let_it_be(:group) { create(:group, :shared_runners_disabled) }

            it 'receives correct method and succeeds' do
              expect(group).to receive(:update_shared_runners_setting!).with(Namespace::SR_DISABLED_WITH_OVERRIDE)

              expect(subject[:status]).to eq(:success)
            end
          end

          context 'when parent does not allow' do
            let_it_be(:parent) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false) }
            let_it_be(:group) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false, parent: parent) }

            it 'results error' do
              expect(subject[:status]).to eq(:error)
              expect(subject[:message]).to eq('Validation failed: Allow descendants override disabled shared runners cannot be enabled because parent group does not allow it')
            end
          end
        end
      end
    end
  end
end
