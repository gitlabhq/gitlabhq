# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::KeyBuilder do
  let_it_be(:personal_key) { create(:personal_key) }
  let_it_be(:other_key) { create(:key) }

  describe '#build' do
    let(:data) { described_class.new(key).build(event) }
    let(:event_name) { data[:event_name] }
    let(:common_attributes) do
      [
        :event_name, :created_at, :updated_at, :key, :id
      ]
    end

    shared_examples_for 'includes the required attributes' do
      it 'includes the required attributes' do
        expect(data.keys).to contain_exactly(*attributes)

        expect(data[:key]).to eq(key.key)
        expect(data[:id]).to eq(key.id)
        expect(data[:created_at]).to eq(key.created_at.xmlschema)
        expect(data[:updated_at]).to eq(key.updated_at.xmlschema)
      end
    end

    context 'for keys that belong to a user' do
      let(:key) { personal_key }
      let(:attributes) { common_attributes.append(:username) }

      context 'data' do
        context 'on create' do
          let(:event) { :create }

          it { expect(event_name).to eq('key_create') }
          it { expect(data[:username]).to eq(key.user.username) }

          it_behaves_like 'includes the required attributes'
        end

        context 'on destroy' do
          let(:event) { :destroy }

          it { expect(event_name).to eq('key_destroy') }
          it { expect(data[:username]).to eq(key.user.username) }

          it_behaves_like 'includes the required attributes'
        end
      end
    end

    context 'for keys that do not belong to a user' do
      let(:key) { other_key }
      let(:attributes) { common_attributes }

      context 'data' do
        context 'on create' do
          let(:event) { :create }

          it { expect(event_name).to eq('key_create') }

          it_behaves_like 'includes the required attributes'
        end

        context 'on destroy' do
          let(:event) { :destroy }

          it { expect(event_name).to eq('key_destroy') }

          it_behaves_like 'includes the required attributes'
        end
      end
    end
  end
end
