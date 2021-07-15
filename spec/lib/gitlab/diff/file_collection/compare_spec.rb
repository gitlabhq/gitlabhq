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

  let(:diffable) { Compare.new(raw_compare, project) }
  let(:collection_default_args) do
    {
      project: diffable.project,
      diff_options: {},
      diff_refs: diffable.diff_refs
    }
  end

  it_behaves_like 'diff statistics' do
    let(:stub_path) { '.gitignore' }
  end

  it_behaves_like 'sortable diff files' do
    let(:unsorted_diff_files_paths) do
      [
        '.DS_Store',
        '.gitignore',
        '.gitmodules',
        'Gemfile.zip',
        'files/.DS_Store',
        'files/ruby/popen.rb',
        'files/ruby/regex.rb',
        'files/ruby/version_info.rb',
        'gitlab-shell'
      ]
    end

    let(:sorted_diff_files_paths) do
      [
        'files/ruby/popen.rb',
        'files/ruby/regex.rb',
        'files/ruby/version_info.rb',
        'files/.DS_Store',
        '.DS_Store',
        '.gitignore',
        '.gitmodules',
        'Gemfile.zip',
        'gitlab-shell'
      ]
    end
  end

  describe '#cache_key' do
    subject(:cache_key) { described_class.new(diffable, **collection_default_args).cache_key }

    it 'returns with head and base' do
      expect(cache_key).to eq ['compare', head_commit.id, start_commit.id]
    end
  end
end
