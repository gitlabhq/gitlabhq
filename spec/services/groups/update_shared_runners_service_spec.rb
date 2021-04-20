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
      end

      context 'disable shared Runners' do
        let_it_be(:group) { create(:group) }

        let(:params) { { shared_runners_setting: 'disabled_and_unoverridable' } }

        it 'receives correct method and succeeds' do
          expect(group).to receive(:update_shared_runners_setting!).with('disabled_and_unoverridable')

          expect(subject[:status]).to eq(:success)
        end
      end

      context 'allow descendants to override' do
        let(:params) { { shared_runners_setting: 'disabled_with_override' } }

        context 'top level group' do
          let_it_be(:group) { create(:group, :shared_runners_disabled) }

          it 'receives correct method and succeeds' do
            expect(group).to receive(:update_shared_runners_setting!).with('disabled_with_override')

            expect(subject[:status]).to eq(:success)
          end
        end

        context 'when parent does not allow' do
          let_it_be(:parent) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false ) }
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
