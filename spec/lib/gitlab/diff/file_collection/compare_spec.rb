# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::Compare do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:commit)  { project.commit }
  let(:start_commit) { sample_image_commit }
  let(:head_commit) { sample_commit }
  let(:raw_compare) do
    Gitlab::Git::Compare.new(project.repository.raw_repository,
                             start_commit.id,
                             head_commit.id)
  end

  it_behaves_like 'diff statistics' do
    let(:collection_default_args) do
      {
        project: diffable.project,
        diff_options: {},
        diff_refs: diffable.diff_refs
      }
    end

    let(:diffable) { Compare.new(raw_compare, project) }
    let(:stub_path) { '.gitignore' }
  end
end
