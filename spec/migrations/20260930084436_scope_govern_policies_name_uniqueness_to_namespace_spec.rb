# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScopeGovernPoliciesNameUniquenessToNamespace, migration: :gitlab_sec,
  feature_category: :security_policy_management do
  let(:connection) { described_class.new.connection }
  let(:policies) { table(:govern_policies, database: :sec) }

  def index_exists?(name)
    connection.index_exists?(:govern_policies, nil, name: name)
  end

  def create_policy(namespace_id:)
    policies.create!(organization_id: 1, namespace_id: namespace_id, name: 'Shared name', trigger_type: 0)
  end

  it 'replaces the organization-wide name index with a namespace-scoped one' do
    reversible_migration do |migration|
      migration.before -> {
        expect(index_exists?(described_class::OLD_INDEX)).to be(true)
        expect(index_exists?(described_class::NEW_INDEX)).to be(false)
      }

      migration.after -> {
        expect(index_exists?(described_class::OLD_INDEX)).to be(false)
        expect(index_exists?(described_class::NEW_INDEX)).to be(true)
      }
    end
  end

  describe '#up' do
    before do
      migrate!
    end

    it 'allows the same name in two namespaces of an organization' do
      create_policy(namespace_id: 1)

      expect { create_policy(namespace_id: 2) }.not_to raise_error
    end

    it 'rejects the same name twice among organization-wide policies' do
      create_policy(namespace_id: nil)

      expect { create_policy(namespace_id: nil) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#down' do
    it 'fails and keeps the namespace-scoped index when two namespaces share a name' do
      migrate!
      create_policy(namespace_id: 1)
      create_policy(namespace_id: 2)

      expect { schema_migrate_down! }.to raise_error(StandardError, /unique/i)
      expect(index_exists?(described_class::NEW_INDEX)).to be(true)
    end
  end
end
