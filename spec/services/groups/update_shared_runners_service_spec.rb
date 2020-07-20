# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateSharedRunnersService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:params) { {} }

  describe '#execute' do
    subject { described_class.new(group, user, params).execute }

    context 'when current_user is not the group owner' do
      let_it_be(:group) { create(:group) }

      let(:params) { { shared_runners_enabled: '0' } }

      before do
        group.add_maintainer(user)
      end

      it 'results error and does not call any method' do
        expect(group).not_to receive(:enable_shared_runners!)
        expect(group).not_to receive(:disable_shared_runners!)
        expect(group).not_to receive(:allow_descendants_override_disabled_shared_runners!)
        expect(group).not_to receive(:disallow_descendants_override_disabled_shared_runners!)

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
        where(:desired_params) do
          ['1', true]
        end

        with_them do
          let(:params) { { shared_runners_enabled: desired_params } }

          context 'group that its ancestors have shared runners disabled' do
            let_it_be(:parent) { create(:group, :shared_runners_disabled) }
            let_it_be(:group) { create(:group, :shared_runners_disabled, parent: parent) }

            it 'results error' do
              expect(subject[:status]).to eq(:error)
              expect(subject[:message]).to eq('Shared Runners disabled for the parent group')
            end
          end

          context 'root group with shared runners disabled' do
            let_it_be(:group) { create(:group, :shared_runners_disabled) }

            it 'receives correct method and succeeds' do
              expect(group).to receive(:enable_shared_runners!)
              expect(group).not_to receive(:disable_shared_runners!)
              expect(group).not_to receive(:allow_descendants_override_disabled_shared_runners!)
              expect(group).not_to receive(:disallow_descendants_override_disabled_shared_runners!)

              expect(subject[:status]).to eq(:success)
            end
          end
        end
      end

      context 'disable shared Runners' do
        let_it_be(:group) { create(:group) }

        where(:desired_params) do
          ['0', false]
        end

        with_them do
          let(:params) { { shared_runners_enabled: desired_params } }

          it 'receives correct method and succeeds' do
            expect(group).to receive(:disable_shared_runners!)
            expect(group).not_to receive(:enable_shared_runners!)
            expect(group).not_to receive(:allow_descendants_override_disabled_shared_runners!)
            expect(group).not_to receive(:disallow_descendants_override_disabled_shared_runners!)

            expect(subject[:status]).to eq(:success)
          end
        end
      end

      context 'allow descendants to override' do
        where(:desired_params) do
          ['1', true]
        end

        with_them do
          let(:params) { { allow_descendants_override_disabled_shared_runners: desired_params } }

          context 'top level group' do
            let_it_be(:group) { create(:group, :shared_runners_disabled) }

            it 'receives correct method and succeeds' do
              expect(group).to receive(:allow_descendants_override_disabled_shared_runners!)
              expect(group).not_to receive(:disallow_descendants_override_disabled_shared_runners!)
              expect(group).not_to receive(:enable_shared_runners!)
              expect(group).not_to receive(:disable_shared_runners!)

              expect(subject[:status]).to eq(:success)
            end
          end

          context 'when parent does not allow' do
            let_it_be(:parent) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false ) }
            let_it_be(:group) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false, parent: parent) }

            it 'results error' do
              expect(subject[:status]).to eq(:error)
              expect(subject[:message]).to eq('Group level shared Runners not allowed')
            end
          end
        end
      end

      context 'disallow descendants to override' do
        where(:desired_params) do
          ['0', false]
        end

        with_them do
          let(:params) { { allow_descendants_override_disabled_shared_runners: desired_params } }

          context 'top level group' do
            let_it_be(:group) { create(:group, :shared_runners_disabled, :allow_descendants_override_disabled_shared_runners ) }

            it 'receives correct method and succeeds' do
              expect(group).to receive(:disallow_descendants_override_disabled_shared_runners!)
              expect(group).not_to receive(:allow_descendants_override_disabled_shared_runners!)
              expect(group).not_to receive(:enable_shared_runners!)
              expect(group).not_to receive(:disable_shared_runners!)

              expect(subject[:status]).to eq(:success)
            end
          end

          context 'top level group that has shared Runners enabled' do
            let_it_be(:group) { create(:group, shared_runners_enabled: true) }

            it 'results error' do
              expect(subject[:status]).to eq(:error)
              expect(subject[:message]).to eq('Shared Runners enabled')
            end
          end
        end
      end

      context 'both params are present' do
        context 'shared_runners_enabled: 1 and allow_descendants_override_disabled_shared_runners' do
          let_it_be(:group) { create(:group, :shared_runners_disabled) }
          let_it_be(:sub_group) { create(:group, :shared_runners_disabled, parent: group) }
          let_it_be(:project) { create(:project, shared_runners_enabled: false, group: sub_group) }

          where(:allow_descendants_override) do
            ['1', true, '0', false]
          end

          with_them do
            let(:params) { { shared_runners_enabled: '1', allow_descendants_override_disabled_shared_runners: allow_descendants_override } }

            it 'results in an error because shared Runners are enabled' do
              expect { subject }
                .to not_change { group.reload.shared_runners_enabled }
                .and not_change { sub_group.reload.shared_runners_enabled }
                .and not_change { project.reload.shared_runners_enabled }
                .and not_change { group.reload.allow_descendants_override_disabled_shared_runners }
                .and not_change { sub_group.reload.allow_descendants_override_disabled_shared_runners }
              expect(subject[:status]).to eq(:error)
              expect(subject[:message]).to eq('Cannot set shared_runners_enabled to true and allow_descendants_override_disabled_shared_runners')
            end
          end
        end

        context 'shared_runners_enabled: 0 and allow_descendants_override_disabled_shared_runners: 0' do
          let_it_be(:group) { create(:group, :allow_descendants_override_disabled_shared_runners) }
          let_it_be(:sub_group) { create(:group, :shared_runners_disabled, :allow_descendants_override_disabled_shared_runners, parent: group) }
          let_it_be(:sub_group_2) { create(:group, parent: group) }
          let_it_be(:project) { create(:project, group: group, shared_runners_enabled: true) }
          let_it_be(:project_2) { create(:project, group: sub_group_2, shared_runners_enabled: true) }

          let(:params) { { shared_runners_enabled: '0', allow_descendants_override_disabled_shared_runners: '0' } }

          it 'disables shared Runners and disable allow_descendants_override_disabled_shared_runners' do
            expect { subject }
              .to change { group.reload.shared_runners_enabled }.from(true).to(false)
              .and change { group.reload.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
              .and not_change { sub_group.reload.shared_runners_enabled }
              .and change { sub_group.reload.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
              .and change { sub_group_2.reload.shared_runners_enabled }.from(true).to(false)
              .and not_change { sub_group_2.reload.allow_descendants_override_disabled_shared_runners }
              .and change { project.reload.shared_runners_enabled }.from(true).to(false)
              .and change { project_2.reload.shared_runners_enabled }.from(true).to(false)
          end
        end

        context 'shared_runners_enabled: 0 and allow_descendants_override_disabled_shared_runners: 1' do
          let_it_be(:group) { create(:group) }
          let_it_be(:sub_group) { create(:group, :shared_runners_disabled, parent: group) }
          let_it_be(:sub_group_2) { create(:group, parent: group) }
          let_it_be(:project) { create(:project, group: group, shared_runners_enabled: true) }
          let_it_be(:project_2) { create(:project, group: sub_group_2, shared_runners_enabled: true) }

          let(:params) { { shared_runners_enabled: '0', allow_descendants_override_disabled_shared_runners: '1' } }

          it 'disables shared Runners and enable allow_descendants_override_disabled_shared_runners only for itself' do
            expect { subject }
              .to change { group.reload.shared_runners_enabled }.from(true).to(false)
              .and change { group.reload.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
              .and not_change { sub_group.reload.shared_runners_enabled }
              .and not_change { sub_group.reload.allow_descendants_override_disabled_shared_runners }
              .and change { sub_group_2.reload.shared_runners_enabled }.from(true).to(false)
              .and not_change { sub_group_2.reload.allow_descendants_override_disabled_shared_runners }
              .and change { project.reload.shared_runners_enabled }.from(true).to(false)
              .and change { project_2.reload.shared_runners_enabled }.from(true).to(false)
          end
        end
      end
    end
  end
end
