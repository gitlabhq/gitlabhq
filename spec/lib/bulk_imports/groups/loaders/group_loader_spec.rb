# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Loaders::GroupLoader do
  describe '#load' do
    let(:user) { create(:user) }
    let(:data) { { foo: :bar } }
    let(:service_double) { instance_double(::Groups::CreateService) }
    let(:entity) { create(:bulk_import_entity) }
    let(:context) do
      instance_double(
        BulkImports::Pipeline::Context,
        entity: entity,
        current_user: user
      )
    end

    subject { described_class.new }

    context 'when user can create group' do
      shared_examples 'calls Group Create Service to create a new group' do
        it 'calls Group Create Service to create a new group' do
          expect(::Groups::CreateService).to receive(:new).with(context.current_user, data).and_return(service_double)
          expect(service_double).to receive(:execute)
          expect(entity).to receive(:update!)

          subject.load(context, data)
        end
      end

      context 'when there is no parent group' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :create_group).and_return(true)
        end

        include_examples 'calls Group Create Service to create a new group'
      end

      context 'when there is parent group' do
        let(:parent) { create(:group) }
        let(:data) { { 'parent_id' => parent.id } }

        before do
          allow(Ability).to receive(:allowed?).with(user, :create_subgroup, parent).and_return(true)
        end

        include_examples 'calls Group Create Service to create a new group'
      end
    end

    context 'when user cannot create group' do
      shared_examples 'does not create new group' do
        it 'does not create new group' do
          expect(::Groups::CreateService).not_to receive(:new)

          subject.load(context, data)
        end
      end

      context 'when there is no parent group' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :create_group).and_return(false)
        end

        include_examples 'does not create new group'
      end

      context 'when there is parent group' do
        let(:parent) { create(:group) }
        let(:data) { { 'parent_id' => parent.id } }

        before do
          allow(Ability).to receive(:allowed?).with(user, :create_subgroup, parent).and_return(false)
        end

        include_examples 'does not create new group'
      end
    end
  end
end
