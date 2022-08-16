# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::SubgroupBuilder do
  let_it_be(:parent_group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: parent_group) }

  describe '#build' do
    let(:data) { described_class.new(subgroup).build(event) }
    let(:event_name) { data[:event_name] }
    let(:attributes) do
      [
        :event_name, :created_at, :updated_at, :name, :path, :full_path, :group_id,
        :parent_group_id, :parent_name, :parent_path, :parent_full_path
      ]
    end

    context 'data' do
      shared_examples_for 'includes the required attributes' do
        it 'includes the required attributes' do
          expect(data).to include(*attributes)

          expect(data[:name]).to eq(subgroup.name)
          expect(data[:path]).to eq(subgroup.path)
          expect(data[:full_path]).to eq(subgroup.full_path)
          expect(data[:group_id]).to eq(subgroup.id)
          expect(data[:created_at]).to eq(subgroup.created_at.xmlschema)
          expect(data[:updated_at]).to eq(subgroup.updated_at.xmlschema)
          expect(data[:parent_name]).to eq(parent_group.name)
          expect(data[:parent_path]).to eq(parent_group.path)
          expect(data[:parent_full_path]).to eq(parent_group.full_path)
          expect(data[:parent_group_id]).to eq(parent_group.id)
        end
      end

      context 'on create' do
        let(:event) { :create }

        it { expect(event_name).to eq('subgroup_create') }

        it_behaves_like 'includes the required attributes'
      end

      context 'on destroy' do
        let(:event) { :destroy }

        it { expect(event_name).to eq('subgroup_destroy') }

        it_behaves_like 'includes the required attributes'
      end
    end
  end
end
