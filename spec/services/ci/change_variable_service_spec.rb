# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ChangeVariableService, feature_category: :ci_variables do
  let(:service) { described_class.new(container: container, current_user: user, params: params) }
  let_it_be(:user) { create(:user) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }

  shared_examples 'create variable flow' do
    context 'with no extra attributes' do
      let(:params) { { variable_params: { key: 'new_variable', value: 'variable_value' }, action: :create } }

      it 'persists a variable' do
        result = nil
        expect { result = execute }.to change(container.variables, :count).from(0).to(1)
        expect(result.masked).to be_falsey
        expect(result.hidden).to be_falsey
      end
    end

    context 'with masked attribute requested to be true' do
      let(:params) do
        { variable_params: { key: 'new_variable', value: 'variable_value', masked: true }, action: :create }
      end

      it 'persists a variable' do
        result = nil
        expect { result = execute }.to change(container.variables, :count).from(0).to(1)
        expect(result.masked).to be_truthy
      end
    end

    context 'with masked attribute requested to be false' do
      let(:params) do
        { variable_params: { key: 'new_variable', value: 'variable_value', masked: false }, action: :create }
      end

      it 'persists a variable' do
        result = nil
        expect { result = execute }.to change(container.variables, :count).from(0).to(1)
        expect(result.masked).to be_falsey
      end
    end

    context 'with masked_and_hidden attribute requested to be true' do
      let(:params) do
        { variable_params: { key: 'new_variable', value: 'variable_value', masked_and_hidden: true },
          action: :create }
      end

      it 'persists a variable and set hidden and masked attributes' do
        result = nil

        expect { result = execute }.to change(container.variables, :count).from(0).to(1)
        expect(result.masked).to be_truthy
        expect(result.hidden).to be_truthy
      end
    end

    context 'with masked_and_hidden attribute requested to be false' do
      let(:params) do
        { variable_params: { key: 'new_variable', value: 'variable_value', masked_and_hidden: false },
          action: :create }
      end

      it 'persists a variable and set hidden and masked attributes' do
        result = nil

        expect { result = execute }.to change(container.variables, :count).from(0).to(1)
        expect(result.masked).to be_falsey
        expect(result.hidden).to be_falsey
      end
    end
  end

  shared_examples 'update variable flow' do
    context 'when a variable is not hidden' do
      let!(:variable) { container.variables.create!(key: 'old_key', value: 'old_value', hidden: false, masked: true) }

      context 'when a change to the masked attribute is requested' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value', masked: false }, action: :update } }

        it 'updates a variable' do
          expect { execute }.to change { variable.reload.value }.from('old_value').to('new_value')
          expect(variable.reload.masked).to be_falsey
        end
      end

      context 'when a masked attribute is not requested for change' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value' }, action: :update } }

        it 'updates a variable' do
          expect { execute }.to change { variable.reload.value }.from('old_value').to('new_value')
          expect(variable.reload.masked).to be_truthy
        end
      end

      context 'when a request is made to change a masked attribute to its current value' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value', masked: true }, action: :update } }

        it 'updates a variable' do
          expect { execute }.to change { variable.reload.value }.from('old_value').to('new_value')
          expect(variable.reload.masked).to be_truthy
        end
      end

      context 'when a request is made to change the hidden attribute' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value', hidden: true }, action: :update } }

        it 'fails to update the hidden attribute' do
          expect(execute.valid?).to be false
          expect(variable.reload.hidden).to be false
        end
      end

      context 'when a request is made to change the hidden attribute to its current value' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value', hidden: false }, action: :update } }

        it 'updates a variable' do
          expect { execute }.to change { variable.reload.value }.from('old_value').to('new_value')
          expect(variable.reload.hidden).to be_falsey
        end
      end

      context 'when a variable does not exist' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value' }, action: :update } }

        before do
          variable.destroy!
        end

        it 'raises a record not found error' do
          expect { execute }.to raise_error(::ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when a variable is hidden' do
      let!(:variable) { container.variables.create!(key: 'old_key', value: 'old_value', hidden: true, masked: true) }

      context 'when a change to the masked attribute is requested' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value', masked: false }, action: :update } }

        it 'fails to update the masked attribute' do
          expect(execute.valid?).to be false
          expect(variable.reload.masked).to be_truthy
        end
      end

      context 'when a masked attribute is not requested for change' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value' }, action: :update } }

        it 'updates a variable' do
          expect { execute }.to change { variable.reload.value }.from('old_value').to('new_value')
          expect(variable.reload.masked).to be_truthy
        end
      end

      context 'when a request is made to change a masked attribute to its current value' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value', masked: true }, action: :update } }

        it 'updates a variable' do
          expect { execute }.to change { variable.reload.value }.from('old_value').to('new_value')
          expect(variable.reload.masked).to be_truthy
        end
      end

      context 'when a request is made to change the hidden attribute' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value', hidden: false }, action: :update } }

        it 'fails to update the hidden attribute' do
          expect(execute.valid?).to be false
          expect(variable.reload.hidden).to be_truthy
        end
      end

      context 'when a request is made to change the hidden attribute to its current value' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value', hidden: true }, action: :update } }

        it 'updates a variable' do
          expect { execute }.to change { variable.reload.value }.from('old_value').to('new_value')
          expect(variable.reload.hidden).to be_truthy
        end
      end

      context 'when a variable does not exist' do
        let(:params) { { variable_params: { key: variable.key, value: 'new_value' }, action: :update } }

        before do
          variable.destroy!
        end

        it 'raises a record not found error' do
          expect { execute }.to raise_error(::ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  shared_examples 'destroy variable flow' do
    let!(:variable) { container.variables.create!(key: 'old_key', value: 'old_value') }
    let(:params) { { variable_params: { key: variable.key }, action: :destroy } }

    it 'destroys a variable' do
      expect { execute }.to change { container.variables.exists?(variable.id) }.from(true).to(false)
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

  describe 'container is a project' do
    let(:container) { project }

    describe '#execute' do
      subject(:execute) { service.execute }

      it_behaves_like 'create variable flow'

      it_behaves_like 'update variable flow'

      it_behaves_like 'destroy variable flow'
    end
  end

  describe 'container is a group' do
    let(:container) { group }

    describe '#execute' do
      subject(:execute) { service.execute }

      it_behaves_like 'create variable flow'

      it_behaves_like 'update variable flow'

      it_behaves_like 'destroy variable flow'
    end
  end
end
