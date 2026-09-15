# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RateLimit::TargetNamespace, :request_store, :use_clean_rails_memory_store_caching,
  feature_category: :rate_limiting do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:personal_project) { create(:project, namespace: user.namespace) }

  let(:root_id) { group.id.to_s }

  def clear_caches
    Rails.cache.clear
    ::Gitlab::SafeRequestStore.clear!
  end

  describe '.id_for_path' do
    it 'folds a group, a subgroup and a project onto the root namespace', :aggregate_failures do
      expect(described_class.id_for_path("/#{group.full_path}/-/issues")).to eq(root_id)
      expect(described_class.id_for_path("/#{subgroup.full_path}")).to eq(root_id)
      expect(described_class.id_for_path("/#{project.full_path}/-/issues/1")).to eq(root_id)
    end

    it 'folds a personal namespace project onto the user namespace' do
      expect(described_class.id_for_path("/#{personal_project.full_path}/-/issues/1"))
        .to eq(user.namespace_id.to_s)
    end

    it 'matches a route whose case differs from the stored path' do
      expect(described_class.id_for_path("/#{project.full_path.upcase}/-/issues/1")).to eq(root_id)
    end

    it 'resolves the numeric API identifiers', :aggregate_failures do
      expect(described_class.id_for_path("/api/v4/projects/#{project.id}/issues")).to eq(root_id)
      expect(described_class.id_for_path("/api/v4/groups/#{subgroup.id}/projects")).to eq(root_id)
    end

    it 'returns nothing for a path that names no namespace', :aggregate_failures do
      expect(described_class.id_for_path('/api/graphql')).to be_nil
      expect(described_class.id_for_path('/dashboard/issues')).to be_nil
    end

    it 'returns nothing for a route, a project and a group that do not exist', :aggregate_failures do
      expect(described_class.id_for_path('/no/such/namespace')).to be_nil
      expect(described_class.id_for_path('/api/v4/projects/0/issues')).to be_nil
      expect(described_class.id_for_path('/api/v4/groups/0/projects')).to be_nil
    end

    it 'runs no query for a target longer than the routes.path column', :aggregate_failures do
      expect { expect(described_class.id_for_path("/#{'a' * 256}")).to be_nil }.not_to exceed_query_limit(0)
      expect { expect(described_class.id_for_path("/api/v4/projects/#{'9' * 256}")).to be_nil }
        .not_to exceed_query_limit(0)
    end

    # String#to_i raises past 4300 digits, so the identifier reaches the models uncast.
    it 'returns nothing for a numeric identifier past the bigint range', :aggregate_failures do
      past_bigint = Gitlab::Database::MAX_BIGINT_VALUE + 1

      expect(described_class.id_for_path("/api/v4/projects/#{past_bigint}")).to be_nil
      expect(described_class.id_for_path("/api/v4/groups/#{past_bigint}")).to be_nil
    end
  end

  describe '.id_for_project' do
    it 'folds a subgroup project onto the root namespace' do
      expect(described_class.id_for_project(project.id)).to eq(root_id)
    end

    it 'returns nothing for a project that does not exist' do
      expect(described_class.id_for_project(non_existing_record_id)).to be_nil
    end
  end

  describe '.id_for_group' do
    it 'folds a subgroup onto the root namespace', :aggregate_failures do
      expect(described_class.id_for_group(subgroup.id)).to eq(root_id)
      expect(described_class.id_for_group(group.id)).to eq(root_id)
    end

    it 'returns nothing for a group that does not exist' do
      expect(described_class.id_for_group(non_existing_record_id)).to be_nil
    end
  end

  describe 'a blank identifier' do
    it 'resolves to nothing without a query', :aggregate_failures do
      expect { expect(described_class.id_for_project(nil)).to be_nil }.not_to exceed_query_limit(0)
      expect { expect(described_class.id_for_group(nil)).to be_nil }.not_to exceed_query_limit(0)
    end

    it 'writes no cache entry', :aggregate_failures do
      described_class.id_for_project(nil)

      expect(Rails.cache.read('namespace_id:project:')).to be_nil
      expect(Rails.cache.read('namespace_id:group:')).to be_nil
    end
  end

  describe 'caching' do
    let(:path) { "/#{project.full_path}/-/issues/1" }

    it 'runs one query on a miss and none on a hit' do
      expect { described_class.id_for_path(path) }.not_to exceed_query_limit(1)

      clear_caches
      described_class.id_for_path(path)
      ::Gitlab::SafeRequestStore.clear!

      expect { expect(described_class.id_for_path(path)).to eq(root_id) }.not_to exceed_query_limit(0)
    end

    # Namespace and Project each expose more than one root-id reader, and the
    # alternatives cost two queries.
    it 'runs one query on a miss for the project and group identifiers', :aggregate_failures do
      expect { described_class.id_for_project(project.id) }.not_to exceed_query_limit(1)
      expect { described_class.id_for_group(subgroup.id) }.not_to exceed_query_limit(1)
    end

    it 'serves a repeat lookup from the request store without reading Rails.cache' do
      described_class.id_for_path(path)

      expect(Rails.cache).not_to receive(:fetch)
      expect(described_class.id_for_path(path)).to eq(root_id)
    end

    # The numeric API path, the job token and the project deploy token all name the
    # same project, so they are meant to share one entry rather than one each.
    it 'shares one entry between the numeric API path and the project identifier' do
      described_class.id_for_path("/api/v4/projects/#{project.id}/issues")
      ::Gitlab::SafeRequestStore.clear!

      expect { expect(described_class.id_for_project(project.id)).to eq(root_id) }.not_to exceed_query_limit(0)
    end

    it 'keeps a project and a group entry apart under the same numeric id', :aggregate_failures do
      described_class.id_for_project(project.id)

      expect(Rails.cache.read("namespace_id:project:#{project.id}")).to eq(root_id)
      expect(Rails.cache.read("namespace_id:group:#{project.id}")).to be_nil
    end

    it 'serves a repeat negative lookup from the request store' do
      described_class.id_for_path('/no/such/namespace')

      expect(Rails.cache).not_to receive(:fetch)
      expect(described_class.id_for_path('/no/such/namespace')).to be_nil
    end

    it 'caches a negative result, so spraying one path cannot force a query per request' do
      expect(described_class.id_for_path('/no/such/namespace')).to be_nil
      ::Gitlab::SafeRequestStore.clear!

      expect { expect(described_class.id_for_path('/no/such/namespace')).to be_nil }.not_to exceed_query_limit(0)
    end

    it 'guards a resolved lookup against the expiry stampede' do
      expect(Rails.cache).to receive(:fetch).with(
        "namespace_id:route:#{project.full_path}",
        expires_in: described_class::CACHE_EXPIRATION,
        race_condition_ttl: described_class::RACE_CONDITION_TTL,
        skip_nil: true
      ).and_call_original

      expect(described_class.id_for_path(path)).to eq(root_id)
    end

    it 'expires a negative entry sooner than a resolved one' do
      expect(Rails.cache).to receive(:write).with(
        'namespace_id:route:no/such/namespace', '', expires_in: described_class::NEGATIVE_CACHE_EXPIRATION
      ).and_call_original

      expect(described_class.id_for_path('/no/such/namespace')).to be_nil
    end
  end
end
