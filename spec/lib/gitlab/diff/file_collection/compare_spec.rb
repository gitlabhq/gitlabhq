# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::Compare do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:commit)  { project.commit }
  let(:start_commit) { sample_image_commit }
  let(:head_commit) { sample_commit }
  let(:raw_compare) do
    Gitlab::Git::Compare.new(
      project.repository.raw_repository,
      start_commit.id,
      head_commit.id
    )
  end

  let(:diffable) { Compare.new(raw_compare, project) }
  let(:diff_options) { {} }
  let(:collection_default_args) do
    {
      project: diffable.project,
      diff_options: diff_options,
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

  describe 'pagination methods' do
    subject(:compare) { described_class.new(diffable, **collection_default_args) }

    context 'when pagination options are not present' do
      it 'returns default values' do
        expect(compare.limit_value).to eq(Kaminari.config.default_per_page)
        expect(compare.current_page).to eq(1)
        expect(compare.next_page).to be_nil
        expect(compare.prev_page).to be_nil
        expect(compare.total_count).to be_nil
        expect(compare.total_pages).to eq(0)
      end
    end

    context 'when pagination options are present' do
      let(:diff_options) { { page: 1, per_page: 10, count: 20 } }

      it 'returns values based on options' do
        expect(compare.limit_value).to eq(10)
        expect(compare.current_page).to eq(1)
        expect(compare.next_page).to eq(2)
        expect(compare.prev_page).to be_nil
        expect(compare.total_count).to eq(20)
        expect(compare.total_pages).to eq(2)
      end
    end
  end
end
