# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ChangeVariableService do
  let(:service) { described_class.new(container: group, current_user: user, params: params) }

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'when creating a variable' do
      let(:params) { { variable_params: { key: 'new_variable', value: 'variable_value' }, action: :create } }

      it 'persists a variable' do
        expect { execute }.to change(Ci::GroupVariable, :count).from(0).to(1)
      end
    end

    context 'when updating a variable' do
      let!(:variable) { create(:ci_group_variable, value: 'old_value') }
      let(:params) { { variable_params: { key: variable.key, value: 'new_value' }, action: :update } }

      before do
        group.variables << variable
      end

      it 'updates a variable' do
        expect { execute }.to change { variable.reload.value }.from('old_value').to('new_value')
      end

      context 'when the variable does not exist' do
        before do
          variable.destroy!
        end

        it 'raises a record not found error' do
          expect { execute }.to raise_error(::ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when destroying a variable' do
      let!(:variable) { create(:ci_group_variable) }
      let(:params) { { variable_params: { key: variable.key }, action: :destroy } }

      before do
        group.variables << variable
      end

      it 'destroys a variable' do
        expect { execute }.to change { Ci::GroupVariable.exists?(variable.id) }.from(true).to(false)
      end

      context 'when the variable does not exist' do
        before do
          variable.destroy!
        end

        it 'raises a record not found error' do
          expect { execute }.to raise_error(::ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
