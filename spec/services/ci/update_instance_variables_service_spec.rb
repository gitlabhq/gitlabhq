# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdateInstanceVariablesService, feature_category: :ci_variables do
  let(:params) { { variables_attributes: variables_attributes } }
  let(:current_user) { build :user }

  subject(:service) { described_class.new(params, current_user) }

  describe '#execute' do
    context 'without variables' do
      let(:variables_attributes) { [] }

      it { expect(service.execute).to be_truthy }
    end

    context 'with insert only variables' do
      let(:variables_attributes) do
        [
          { key: 'var_a', secret_value: 'dummy_value_for_a', protected: true },
          { key: 'var_b', secret_value: 'dummy_value_for_b', protected: false }
        ]
      end

      it { expect(service.execute).to be_truthy }

      it 'persists all the records' do
        expect { service.execute }
          .to change { Ci::InstanceVariable.count }
          .by variables_attributes.size
      end

      it 'persists attributes' do
        service.execute

        expect(Ci::InstanceVariable.all).to contain_exactly(
          have_attributes(key: 'var_a', secret_value: 'dummy_value_for_a', protected: true),
          have_attributes(key: 'var_b', secret_value: 'dummy_value_for_b', protected: false)
        )
      end
    end

    context 'with update only variables' do
      let!(:var_a) { create(:ci_instance_variable) }
      let!(:var_b) { create(:ci_instance_variable, protected: false) }

      let(:variables_attributes) do
        [
          {
            id: var_a.id,
            key: var_a.key,
            secret_value: 'new_dummy_value_for_a',
            protected: var_a.protected?.to_s
          },
          {
            id: var_b.id,
            key: 'var_b_key',
            secret_value: 'new_dummy_value_for_b',
            protected: 'true'
          }
        ]
      end

      it { expect(service.execute).to be_truthy }

      it 'does not change the count' do
        expect { service.execute }
          .not_to change { Ci::InstanceVariable.count }
      end

      it 'updates the records in place', :aggregate_failures do
        service.execute

        expect(var_a.reload).to have_attributes(secret_value: 'new_dummy_value_for_a')

        expect(var_b.reload).to have_attributes(
          key: 'var_b_key', secret_value: 'new_dummy_value_for_b', protected: true)
      end
    end

    context 'with insert and update variables' do
      let!(:var_a) { create(:ci_instance_variable) }

      let(:variables_attributes) do
        [
          {
            id: var_a.id,
            key: var_a.key,
            secret_value: 'new_dummy_value_for_a',
            protected: var_a.protected?.to_s
          },
          {
            key: 'var_b',
            secret_value: 'dummy_value_for_b',
            protected: true
          }
        ]
      end

      it { expect(service.execute).to be_truthy }

      it 'inserts only one record' do
        expect { service.execute }
          .to change { Ci::InstanceVariable.count }.by 1
      end

      it 'persists all the records', :aggregate_failures do
        service.execute
        var_b = Ci::InstanceVariable.find_by(key: 'var_b')

        expect(var_a.reload.secret_value).to eq('new_dummy_value_for_a')
        expect(var_b.secret_value).to eq('dummy_value_for_b')
      end
    end

    context 'with insert, update, and destroy variables' do
      let!(:var_a) { create(:ci_instance_variable) }
      let!(:var_b) { create(:ci_instance_variable) }

      let(:variables_attributes) do
        [
          {
            id: var_a.id,
            key: var_a.key,
            secret_value: 'new_dummy_value_for_a',
            protected: var_a.protected?.to_s
          },
          {
            id: var_b.id,
            key: var_b.key,
            secret_value: 'dummy_value_for_b',
            protected: var_b.protected?.to_s,
            '_destroy' => 'true'
          },
          {
            key: 'var_c',
            secret_value: 'dummy_value_for_c',
            protected: true
          }
        ]
      end

      it { expect(service.execute).to be_truthy }

      it 'persists all the records', :aggregate_failures do
        service.execute
        var_c = Ci::InstanceVariable.find_by(key: 'var_c')

        expect(var_a.reload.secret_value).to eq('new_dummy_value_for_a')
        expect { var_b.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(var_c.secret_value).to eq('dummy_value_for_c')
      end
    end

    context 'with invalid variables' do
      let!(:var_a) { create(:ci_instance_variable, secret_value: 'dummy_value_for_a') }

      let(:variables_attributes) do
        [
          {
            key: '...?',
            secret_value: 'nice_value'
          },
          {
            id: var_a.id,
            key: var_a.key,
            secret_value: 'new_dummy_value_for_a',
            protected: var_a.protected?.to_s
          },
          {
            key: var_a.key,
            secret_value: 'other_value'
          }
        ]
      end

      it { expect(service.execute).to be_falsey }

      it 'does not insert any records' do
        expect { service.execute }
          .not_to change { Ci::InstanceVariable.count }
      end

      it 'does not update existing records' do
        service.execute

        expect(var_a.reload.secret_value).to eq('dummy_value_for_a')
      end

      it 'returns errors' do
        service.execute

        expect(service.errors).to match_array(
          [
            "Key (#{var_a.key}) has already been taken",
            "Key can contain only letters, digits and '_'."
          ])
      end
    end

    context 'when deleting non existing variables' do
      let(:variables_attributes) do
        [
          {
            id: 'some-id',
            key: 'some_key',
            secret_value: 'other_value',
            '_destroy' => 'true'
          }
        ]
      end

      it { expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'when updating non existing variables' do
      let(:variables_attributes) do
        [
          {
            id: 'some-id',
            key: 'some_key',
            secret_value: 'other_value'
          }
        ]
      end

      it { expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
