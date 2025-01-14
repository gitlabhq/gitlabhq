# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Network::Graph, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }

  shared_examples 'a collection of commits' do
    it 'returns a list of commits' do
      commits = graph.commits

      expect(commits).not_to be_empty
      expect(commits).to all(be_kind_of(Network::Commit))
    end

    it 'sorts commits by commit date (descending)' do
      # Remove duplicate timestamps because they make it harder to
      # assert that the commits are sorted as expected.
      commits = graph.commits.uniq(&:date)
      sorted_commits = commits.sort_by(&:date).reverse

      expect(commits).not_to be_empty
      expect(commits.map(&:id)).to eq(sorted_commits.map(&:id))
    end

    it 'sorts children before parents for commits with the same timestamp' do
      commits_by_time = graph.commits.group_by(&:date)

      commits_by_time.each do |_, commits|
        commit_ids = commits.map(&:id)

        commits.each_with_index do |commit, index|
          parent_indexes = commit.parent_ids.map { |parent_id| commit_ids.find_index(parent_id) }.compact

          # All parents of the current commit should appear after it
          expect(parent_indexes).to all(be > index)
        end
      end
    end
  end

  describe '#initialize' do
    let(:graph) do
      described_class.new(project, 'refs/heads/master', project.repository.commit, nil)
    end

    it 'has initialized' do
      expect(graph).to be_a(described_class)
    end
  end

  describe '#commits' do
    let(:graph) { described_class.new(project, 'refs/heads/master', project.repository.commit, nil) }

    let(:opts) do
      {
        revisions: %w[--tags --branches],
        pagination_params: { limit: 650 },
        reverse: false,
        order: :date,
        ref: 'refs/heads/master',
        skip: 0
      }
    end

    it 'only fetches the commits once using `list_all`', :request_store do
      expect(Gitlab::Git::Commit).to receive(:list_all)
                                       .with(project.repository.raw_repository, opts)
                                       .once
                                       .and_call_original

      graph
    end

    it_behaves_like 'a collection of commits'
  end
end
