# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::Commit do
  let(:project) { create(:project, :repository) }
  let(:diffable) { project.commit }

  let(:collection_default_args) do
    { diff_options: {} }
  end

  it_behaves_like 'diff statistics' do
    let(:stub_path) { 'bar/branch-test.txt' }
  end

  it_behaves_like 'unfoldable diff'

  it_behaves_like 'sortable diff files' do
    let(:diffable) { project.commit('913c66a') }

    let(:unsorted_diff_files_paths) do
      [
        '.DS_Store',
        'CHANGELOG',
        'MAINTENANCE.md',
        'PROCESS.md',
        'VERSION',
        'encoding/feature-1.txt',
        'encoding/feature-2.txt',
        'encoding/hotfix-1.txt',
        'encoding/hotfix-2.txt',
        'encoding/russian.rb',
        'encoding/test.txt',
        'encoding/テスト.txt',
        'encoding/テスト.xls',
        'files/.DS_Store',
        'files/html/500.html',
        'files/images/logo-black.png',
        'files/images/logo-white.png',
        'files/js/application.js',
        'files/js/commit.js.coffee',
        'files/markdown/ruby-style-guide.md',
        'files/ruby/popen.rb',
        'files/ruby/regex.rb',
        'files/ruby/version_info.rb'
      ]
    end

    let(:sorted_diff_files_paths) do
      [
        'encoding/feature-1.txt',
        'encoding/feature-2.txt',
        'encoding/hotfix-1.txt',
        'encoding/hotfix-2.txt',
        'encoding/russian.rb',
        'encoding/test.txt',
        'encoding/テスト.txt',
        'encoding/テスト.xls',
        'files/html/500.html',
        'files/images/logo-black.png',
        'files/images/logo-white.png',
        'files/js/application.js',
        'files/js/commit.js.coffee',
        'files/markdown/ruby-style-guide.md',
        'files/ruby/popen.rb',
        'files/ruby/regex.rb',
        'files/ruby/version_info.rb',
        'files/.DS_Store',
        '.DS_Store',
        'CHANGELOG',
        'MAINTENANCE.md',
        'PROCESS.md',
        'VERSION'
      ]
    end
  end

  describe '#cache_key' do
    subject(:cache_key) { described_class.new(diffable, diff_options: nil).cache_key }

    it 'returns with the commit id' do
      expect(cache_key).to eq ['commit', diffable.id]
    end
  end
end
