# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DeleteRelationWithReturning, feature_category: :shared do
  describe '.execute' do
    let(:relation) { double }
    let(:returning) { [] }

    subject(:execute) { described_class.execute(relation, returning) }

    it 'instantiates a service object and sends execute message to it' do
      expect_next_instance_of(described_class, relation, returning) do |service_object|
        expect(service_object).to receive(:execute)
      end

      execute
    end
  end

  describe '#execute' do
    let!(:users) { create_list(:user, 3) }
    let(:relation) { User.order(id: :asc).limit(2) }
    let(:returning) { [:id, :email] }
    let(:service_object) { described_class.new(relation, returning) }

    subject(:delete_relation) { service_object.execute }

    it 'returns the requested attributes of the deleted records' do
      expect(delete_relation).to contain_exactly(
        { 'email' => users.first.email, 'id' => users.first.id },
        { 'email' => users.second.email, 'id' => users.second.id }
      )
    end

    it 'removes the records matching the given relation' do
      expect { delete_relation }.to change { users.first.deleted_from_database? }.from(false).to(true)
                                .and change { users.second.deleted_from_database? }.from(false).to(true)
                                .and not_change { users.third.deleted_from_database? }.from(false)
    end
  end
end
