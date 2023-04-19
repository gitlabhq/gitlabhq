# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).tagsTippingAtCommit(commitSha)', feature_category: :source_code_management do
  include GraphqlHelpers
  include Presentable

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository.raw }
  let_it_be(:current_user) { project.first_owner }
  let_it_be(:branches_names) { %w[master not-merged-branch v1.1.0] }

  let(:post_query) { post_graphql(query, current_user: current_user) }
  let(:path) { %w[project branchesTippingAtCommit names] }
  let(:data) { graphql_data.dig(*path) }

  let(:query) do
    graphql_query_for(
      :project,
      { fullPath: project.full_path },
      query_graphql_field(:branchesTippingAtCommit, { commitSha: commit_sha }, :names)
    )
  end

  context 'when commit exists and is tipping branches' do
    let_it_be(:commit_sha) { repository.commit.id }

    context 'with authorized user' do
      it 'returns branches names tipping the commit' do
        post_query

        expect(data).to eq(branches_names)
      end
    end

    context 'when user is not authorized' do
      let(:current_user) { create(:user) }

      it 'returns branches names tipping the commit' do
        post_query

        expect(data).to eq(nil)
      end
    end
  end

  context 'when commit does not exist' do
    let(:commit_sha) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff4' }

    it 'returns tags names tipping the commit' do
      post_query

      expect(data).to eq([])
    end
  end

  context 'when commit exists but does not tip any branches' do
    let(:commit_sha) { project.repository.commits(nil, { limit: 4 }).commits[2].id }

    it 'returns tags names tipping the commit' do
      post_query

      expect(data).to eq([])
    end
  end
end
