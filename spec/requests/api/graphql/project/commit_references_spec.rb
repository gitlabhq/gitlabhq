# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).commitReferences(commitSha)', feature_category: :source_code_management do
  include GraphqlHelpers
  include Presentable

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository.raw }
  let_it_be(:current_user) { project.first_owner }
  let_it_be(:branches_names) { %w[master not-merged-branch v1.1.0] }
  let_it_be(:tag_name) { 'v1.0.0' }
  let_it_be(:commit_sha) { repository.commit.id }

  let(:post_query) { post_graphql(query, current_user: current_user) }
  let(:data) { graphql_data.dig(*path) }
  let(:base_args) { {} }
  let(:args) { base_args }

  shared_context 'with the limit argument' do
    context 'with limit of 2' do
      let(:args) { { limit: 2 } }

      it 'returns the right amount of refs' do
        post_query
        expect(data.count).to be <= 2
      end
    end

    context 'with limit of -2' do
      let(:args) { { limit: -2 } }

      it 'casts an argument error "limit must be greater then 0"' do
        post_query
        expect(graphql_errors).to include(custom_graphql_error(path - ['names'],
          'limit must be within 1..1000'))
      end
    end

    context 'with limit of 1001' do
      let(:args) { { limit: 1001 } }

      it 'casts an argument error "limit must be greater then 0"' do
        post_query
        expect(graphql_errors).to include(custom_graphql_error(path - ['names'],
          'limit must be within 1..1000'))
      end
    end
  end

  describe 'the path commitReferences should return nil' do
    let(:path) { %w[project commitReferences] }

    let(:query) do
      graphql_query_for(:project, { fullPath: project.full_path },
        query_graphql_field(
          :commitReferences,
          { commitSha: commit_sha },
          query_graphql_field(:tippingTags, :names)
        )
      )
    end

    context 'when commit does not exist' do
      let(:commit_sha) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff4' }

      it 'commitReferences returns nil' do
        post_query
        expect(data).to eq(nil)
      end
    end

    context 'when sha length is incorrect' do
      let(:commit_sha) { 'foo' }

      it 'commitReferences returns nil' do
        post_query
        expect(data).to eq(nil)
      end
    end

    context 'when user is not authorized' do
      let(:commit_sha) { repository.commit.id }
      let(:current_user) { create(:user) }

      it 'commitReferences returns nil' do
        post_query
        expect(data).to eq(nil)
      end
    end
  end

  context 'with containing refs' do
    let(:base_args) { { excludeTipped: false } }
    let(:excluded_tipped_args) do
      hash = base_args.dup
      hash[:excludeTipped] = true
      hash
    end

    context 'with path Query.project(fullPath).commitReferences(commitSha).containingTags' do
      let_it_be(:commit_sha) { repository.find_tag(tag_name).target_commit.sha }
      let_it_be(:path) { %w[project commitReferences containingTags names] }
      let(:query) do
        graphql_query_for(
          :project,
          { fullPath: project.full_path },
          query_graphql_field(
            :commitReferences,
            { commitSha: commit_sha },
            query_graphql_field(:containingTags, args, :names)
          )
        )
      end

      context 'without excludeTipped argument' do
        it 'returns tags names containing the commit' do
          post_query
          expect(data).to eq(%w[v1.0.0 v1.1.0 v1.1.1])
        end
      end

      context 'with excludeTipped argument' do
        let_it_be(:ref_prefix) { Gitlab::Git::TAG_REF_PREFIX }

        let(:args) { excluded_tipped_args }

        it 'returns tags names containing the commit without the tipped tags' do
          excluded_refs = project.repository
                                 .refs_by_oid(oid: commit_sha, ref_patterns: [ref_prefix])
                                 .map { |n| n.delete_prefix(ref_prefix) }

          post_query
          expect(data).to eq(%w[v1.0.0 v1.1.0 v1.1.1] - excluded_refs)
        end
      end

      include_context 'with the limit argument'
    end

    context 'with path Query.project(fullPath).commitReferences(commitSha).containingBranches' do
      let_it_be(:ref_prefix) { Gitlab::Git::BRANCH_REF_PREFIX }
      let_it_be(:path) { %w[project commitReferences containingBranches names] }

      let(:query) do
        graphql_query_for(
          :project,
          { fullPath: project.full_path },
          query_graphql_field(
            :commitReferences,
            { commitSha: commit_sha },
            query_graphql_field(:containingBranches, args, :names)
          )
        )
      end

      context 'without excludeTipped argument' do
        it 'returns branch names containing the commit' do
          refs = project.repository.branch_names_contains(commit_sha)

          post_query

          expect(data).to eq(refs)
        end
      end

      context 'with excludeTipped argument' do
        let(:args) { excluded_tipped_args }

        it 'returns branch names containing the commit without the tipped branch' do
          refs = project.repository.branch_names_contains(commit_sha)

          excluded_refs = project.repository
                                 .refs_by_oid(oid: commit_sha, ref_patterns: [ref_prefix])
                                 .map { |n| n.delete_prefix(ref_prefix) }

          post_query

          expect(data).to eq(refs - excluded_refs)
        end
      end

      include_context 'with the limit argument'
    end
  end

  context 'with tipping refs' do
    context 'with path Query.project(fullPath).commitReferences(commitSha).tippingTags' do
      let(:commit_sha) { repository.find_tag(tag_name).dereferenced_target.sha }
      let(:path) { %w[project commitReferences tippingTags names] }

      let(:query) do
        graphql_query_for(
          :project,
          { fullPath: project.full_path },
          query_graphql_field(
            :commitReferences,
            { commitSha: commit_sha },
            query_graphql_field(:tippingTags, args, :names)
          )
        )
      end

      context 'with authorized user' do
        it 'returns tags names tipping the commit' do
          post_query

          expect(data).to eq([tag_name])
        end
      end

      include_context 'with the limit argument'
    end

    context 'with path Query.project(fullPath).commitReferences(commitSha).tippingBranches' do
      let(:path) { %w[project commitReferences tippingBranches names] }

      let(:query) do
        graphql_query_for(
          :project,
          { fullPath: project.full_path },
          query_graphql_field(
            :commitReferences,
            { commitSha: commit_sha },
            query_graphql_field(:tippingBranches, args, :names)
          )
        )
      end

      it 'returns branches names tipping the commit' do
        post_query

        expect(data).to eq(branches_names)
      end

      include_context 'with the limit argument'
    end
  end
end
