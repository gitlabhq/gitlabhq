# frozen_string_literal: true

RSpec.shared_examples 'search results filtered by language' do
  let(:scope) { 'blobs' }
  let(:filters) { { language: %w[Ruby Markdown] } }
  let(:query) { 'def | popen | test' }

  before do
    project.repository.index_commits_and_blobs

    ensure_elasticsearch_index!
  end

  subject(:blob_results) { results.objects('blobs') }

  it 'filters by language', :sidekiq_inline, :aggregate_failures do
    expected_paths = %w[
      files/ruby/popen.rb
      files/markdown/ruby-style-guide.md
      files/ruby/regex.rb
      files/ruby/version_info.rb
      CONTRIBUTING.md
    ]

    paths = blob_results.map { |blob| blob.binary_path }
    expect(blob_results.size).to eq(5)
    expect(paths).to match_array(expected_paths)
  end

  context 'when the search_blobs_language_aggregation feature flag is disabled' do
    before do
      stub_feature_flags(search_blobs_language_aggregation: false)
    end

    it 'does not filter by language', :sidekiq_inline, :aggregate_failures do
      expected_paths = %w[
        CHANGELOG
        CONTRIBUTING.md
        bar/branch-test.txt
        custom-highlighting/test.gitlab-custom
        files/ruby/popen.rb
        files/ruby/regex.rb
        files/ruby/version_info.rb
        files/whitespace
        encoding/test.txt
        files/markdown/ruby-style-guide.md
      ]

      paths = blob_results.map { |blob| blob.binary_path }
      expect(blob_results.size).to eq(10)
      expect(paths).to match_array(expected_paths)
    end
  end
end
