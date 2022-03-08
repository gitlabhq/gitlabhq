# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::BatchCommitLoader do
  include RepoHelpers

  describe '#find' do
    let_it_be(:first_project) { create(:project, :repository) }
    let_it_be(:second_project) { create(:project, :repository) }

    let_it_be(:first_commit) { first_project.commit(sample_commit.id) }
    let_it_be(:second_commit) { first_project.commit(another_sample_commit.id) }
    let_it_be(:third_commit) { second_project.commit(sample_big_commit.id) }

    it 'finds a commit by id' do
      result = described_class.new(
        container_class: Project,
        container_id: first_project.id,
        oid: first_commit.id
      ).find

      expect(result.force).to eq(first_commit)
    end

    it 'only queries once' do
      expect do
        [
          described_class.new(
            container_class: Project,
            container_id: first_project.id,
            oid: first_commit.id
          ).find,
          described_class.new(
            container_class: Project,
            container_id: first_project.id,
            oid: second_commit.id
          ).find,
          described_class.new(
            container_class: Project,
            container_id: second_project.id,
            oid: third_commit.id
          ).find
        ].map(&:force)
      end.not_to exceed_query_limit(2)
    end
  end
end
