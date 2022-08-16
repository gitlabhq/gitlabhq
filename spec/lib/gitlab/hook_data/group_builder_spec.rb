# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::GroupBuilder do
  let_it_be(:group) { create(:group) }

  describe '#build' do
    let(:data) { described_class.new(group).build(event) }
    let(:event_name) { data[:event_name] }
    let(:attributes) do
      [
        :event_name, :created_at, :updated_at, :name, :path, :full_path, :group_id
      ]
    end

    context 'data' do
      shared_examples_for 'includes the required attributes' do
        it 'includes the required attributes' do
          expect(data).to include(*attributes)

          expect(data[:name]).to eq(group.name)
          expect(data[:path]).to eq(group.path)
          expect(data[:full_path]).to eq(group.full_path)
          expect(data[:group_id]).to eq(group.id)
          expect(data[:created_at]).to eq(group.created_at.xmlschema)
          expect(data[:updated_at]).to eq(group.updated_at.xmlschema)
        end
      end

      shared_examples_for 'does not include old path attributes' do
        it 'does not include old path attributes' do
          expect(data).not_to include(:old_path, :old_full_path)
        end
      end

      context 'on create' do
        let(:event) { :create }

        it { expect(event_name).to eq('group_create') }

        it_behaves_like 'includes the required attributes'
        it_behaves_like 'does not include old path attributes'
      end

      context 'on destroy' do
        let(:event) { :destroy }

        it { expect(event_name).to eq('group_destroy') }

        it_behaves_like 'includes the required attributes'
        it_behaves_like 'does not include old path attributes'
      end

      context 'on rename' do
        let(:event) { :rename }

        it { expect(event_name).to eq('group_rename') }

        it_behaves_like 'includes the required attributes'

        it 'includes old path details' do
          allow(group).to receive(:path_before_last_save).and_return('old-path')

          expect(data[:old_path]).to eq(group.path_before_last_save)
          expect(data[:old_full_path]).to eq(group.path_before_last_save)
        end
      end
    end
  end
end
