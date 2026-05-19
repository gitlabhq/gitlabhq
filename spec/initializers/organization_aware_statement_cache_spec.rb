# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OrganizationAwareStatementCache, feature_category: :organization do
  let_it_be(:organization_a) { create(:organization) }
  let_it_be(:organization_b) { create(:organization) }

  let(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = :users
    end
  end

  let(:connection) { model.connection }
  let(:key) { :test_statement_key }

  # A valid Arel block that StatementCache.create can accept
  let(:block) { proc { |params| model.where(id: params.bind).limit(1) } }

  def stored_cache_keys
    model.instance_variable_get(:@find_by_statement_cache)[connection.prepared_statements].keys
  end

  describe '#cached_find_by_statement' do
    context 'without an organization context' do
      before do
        allow(::Current).to receive_messages(organization_assigned: false, organization: nil)
      end

      it 'stores the entry under the plain key' do
        model.cached_find_by_statement(connection, key, &block)

        expect(stored_cache_keys).to include(key)
      end

      it 'reuses the same cache entry on repeated calls' do
        model.cached_find_by_statement(connection, key, &block)
        model.cached_find_by_statement(connection, key, &block)

        expect(stored_cache_keys.count { |k| k == key }).to eq(1)
      end
    end

    context 'with an organization context' do
      before do
        stub_current_organization(organization_a)
      end

      it 'stores the entry under a key scoped to the organization' do
        model.cached_find_by_statement(connection, key, &block)

        expect(stored_cache_keys).to include([key, organization_a.id])
      end

      it 'reuses the same cache entry within the same organization' do
        model.cached_find_by_statement(connection, key, &block)
        model.cached_find_by_statement(connection, key, &block)

        expect(stored_cache_keys.count { |k| k == [key, organization_a.id] }).to eq(1)
      end

      it 'uses a separate cache entry for a different organization' do
        model.cached_find_by_statement(connection, key, &block)

        stub_current_organization(organization_b)
        model.cached_find_by_statement(connection, key, &block)

        expect(stored_cache_keys).to include([key, organization_a.id], [key, organization_b.id])
      end

      it 'uses a separate cache entry from the no-organization context' do
        allow(::Current).to receive_messages(organization_assigned: false, organization: nil)
        model.cached_find_by_statement(connection, key, &block)

        stub_current_organization(organization_a)
        model.cached_find_by_statement(connection, key, &block)

        expect(stored_cache_keys).to include(key, [key, organization_a.id])
      end
    end
  end
end
