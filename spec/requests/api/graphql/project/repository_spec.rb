# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a repository in a project', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }

  let(:current_user) { project.first_owner }
  let(:fields) { all_graphql_fields_for('Repository') }
  let(:query) do
    graphql_query_for(
      'project',
      { fullPath: project.full_path },
      query_graphql_field('repository', {}, fields)
    )
  end

  it 'returns repository' do
    post_graphql(query, current_user: current_user)

    expect(graphql_data['project']['repository']).to be_present
  end

  context 'as a non-authorized user' do
    let(:current_user) { create(:user) }

    it 'returns nil' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).to be_nil
    end
  end

  context 'as a non-admin' do
    let(:current_user) { create(:user) }

    before do
      project.add_role(current_user, :developer) # rubocop:disable RSpec/BeforeAllRoleAssignment -- This incorrectly flags because the let_it_be(:current_user) has been overridden by let(:current_user)
    end

    it 'does not return diskPath' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']).not_to be_nil
      expect(graphql_data['project']['repository']['diskPath']).to be_nil
    end
  end

  context 'as an admin' do
    it 'returns diskPath' do
      post_graphql(query, current_user: create(:admin))

      expect(graphql_data['project']['repository']).not_to be_nil
      expect(graphql_data['project']['repository']['diskPath']).to eq project.disk_path
    end
  end

  context 'when the repository is only accessible to members' do
    let(:project) do
      create(:project, :public, :repository, repository_access_level: ProjectFeature::PRIVATE)
    end

    it 'returns a repository for the owner' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']).not_to be_nil
    end

    it 'returns nil for the repository for other users' do
      post_graphql(query, current_user: create(:user))

      expect(graphql_data['project']['repository']).to be_nil
    end

    it 'returns nil for the repository for other users' do
      post_graphql(query, current_user: nil)

      expect(graphql_data['project']['repository']).to be_nil
    end
  end

  context 'when paginated tree requested' do
    let(:fields) do
      %(
        paginatedTree {
          nodes {
            trees {
              nodes {
                path
              }
            }
          }
        }
      )
    end

    it 'returns paginated tree' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['paginatedTree']).to be_present
    end
  end

  context 'when commit is requested' do
    let(:fields) do
      %(
        commit(ref: "#{ref}") {
          sha
        }
      )
    end

    let(:ref) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

    it 'returns requested commit' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data.dig('project', 'repository', 'commit', 'sha')).to eq ref
    end

    context 'when ref does not point to an existing commit' do
      let(:ref) { 'unknown' }

      it 'returns nil' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data.dig('project', 'repository', 'commit')).to be_nil
      end
    end
  end

  describe 'commits field' do
    let(:ref) { nil }
    let(:query_arg) { nil }
    let(:author) { nil }
    let(:committed_before) { nil }
    let(:committed_after) { nil }
    let(:first) { nil }
    let(:after) { nil }
    let(:commit_nodes) { graphql_data_at(:project, :repository, :commits, :nodes) }
    let(:page_info) { graphql_data_at(:project, :repository, :commits, :pageInfo) }

    let(:arguments) do
      {
        ref: ref,
        query: query_arg,
        author: author,
        committedBefore: committed_before,
        committedAfter: committed_after,
        first: first,
        after: after
      }.compact
    end

    let(:fields) do
      query_graphql_field('commits', arguments, <<~FIELDS)
        pageInfo {
          hasNextPage
          startCursor
          endCursor
        }
        nodes {
          sha
          parentSha
          authorName
          title
          committedDate
        }
      FIELDS
    end

    before do
      allow_next_instance_of(::Resolvers::Repositories::CommitsResolver) do |resolver|
        allow(resolver).to receive(:repository).and_return(repository)
      end
      allow(repository).to receive(:list_commits).and_call_original
      post_graphql(query, current_user: current_user)
    end

    context 'when a valid ref is supplied' do
      let(:ref) { 'master' }

      it 'returns commits' do
        expect(commit_nodes).to be_present
        expect(commit_nodes.pluck('sha')).to eq(repository.list_commits(ref: ref).commits.map(&:sha))
      end

      it 'includes start_cursor and end_cursor for pagination' do
        expect(page_info['hasNextPage']).to be(true)
        expect(page_info['startCursor']).to eq(Base64.encode64(commit_nodes.first['sha']))
        expect(page_info['endCursor']).to eq(Base64.encode64(commit_nodes.last['sha']))
      end

      describe 'query' do
        let(:query_arg) { 'Merge branch' }

        it 'returns commits with messages matching the query' do
          expect(commit_nodes.pluck('title')).to all start_with(query_arg)
        end
      end

      describe 'author' do
        let(:author) { 'Stan' }

        it 'returns commits authored by the supplied author name pattern' do
          expect(commit_nodes.pluck('authorName')).to all start_with(author)
        end
      end

      describe 'pagination params' do
        let(:max_page_size) { Types::RepositoryType.fields['commits'].max_page_size }

        context 'with a page size lower than the max_page_size' do
          let(:first) { max_page_size - 1 }

          it 'respects the passed value' do
            expect(repository)
              .to have_received(:list_commits)
              .with(a_hash_including(pagination_params: { limit: first }))
          end
        end

        context 'with a page size exceeding the max_page_size' do
          let(:first) { max_page_size + 1 }

          it 'respects the default_max_page_size' do
            expect(repository)
              .to have_received(:list_commits)
              .with(a_hash_including(pagination_params: { limit: max_page_size }))
          end
        end

        context 'with limit omitted' do
          it 'picks the fields max_page_size' do
            expect(repository)
              .to have_received(:list_commits)
              .with(a_hash_including(pagination_params: { limit: max_page_size }))
          end
        end

        context 'with null limit' do
          let(:arguments) { { ref: "master", first: nil } }

          it 'picks the fields max_page_size' do
            expect(repository)
              .to have_received(:list_commits)
              .with(a_hash_including(pagination_params: { limit: max_page_size }))
          end
        end

        context 'with a page_token' do
          # Currently we are manually encoding these tokens as gitaly doesn't
          # yet. Once gitaly starts returning tokens we can remove this
          # encode/decode step
          let(:page_token) { 'page_token' }
          let(:after) { Base64.encode64(page_token).strip }

          it 'passes the decoded page_token' do
            expect(repository)
              .to have_received(:list_commits)
              .with(a_hash_including(pagination_params: { limit: max_page_size, page_token: page_token }))
          end
        end
      end

      describe 'committed_before' do
        context 'when valid' do
          let(:committed_before) { '2015-01-01' }
          let(:before_date) { committed_before.to_date }

          it 'only returns commits before the supplied date' do
            expect(commit_nodes).to be_present
            committed_ats = commit_nodes.pluck('committedDate').map(&:to_date)
            expect(committed_ats).to all be <= before_date
          end
        end

        context 'when invalid' do
          let(:committed_before) { 'xxx' }
          let(:error_msg) { 'no time information in "xxx"' }

          it 'error' do
            expect_graphql_errors_to_include(error_msg)
          end
        end
      end

      describe 'committed_after' do
        context 'when valid' do
          let(:committed_after) { '2015-01-01' }
          let(:after_date) { committed_after.to_date }

          it 'only returns commits after the supplied date' do
            expect(commit_nodes).to be_present
            committed_ats = commit_nodes.pluck('committedDate').map(&:to_date)
            expect(committed_ats).to all be >= after_date
          end
        end

        context 'when invalid' do
          let(:committed_after) { 'xxx' }
          let(:error_msg) { 'no time information in "xxx"' }

          it { expect_graphql_errors_to_include(error_msg) }
        end
      end
    end

    context 'when ref is not found' do
      let(:ref) { 'unknown' }
      let(:error_msg) { 'ListCommits: Gitlab::Git::CommandError' }

      it { expect_graphql_errors_to_include(error_msg) }
    end

    context 'when ref is empty' do
      let(:ref) { '' }

      it { expect(commit_nodes).to be_empty }
    end

    context 'when ref is null' do
      let(:arguments) { "ref: null" }
      let(:error_msg) { "Argument 'ref' on Field 'commits' has an invalid value (null). Expected type 'String!'." }

      it { expect_graphql_errors_to_include(error_msg) }
    end
  end
end
