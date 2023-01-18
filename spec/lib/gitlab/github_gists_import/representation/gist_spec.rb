# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::Representation::Gist, feature_category: :importers do
  shared_examples 'a Gist' do
    it 'returns an instance of Gist' do
      expect(gist).to be_an_instance_of(described_class)
    end

    context 'with Gist' do
      it 'includes gist attributes' do
        expect(gist).to have_attributes(
          id: '1',
          description: 'Gist title',
          is_public: true,
          files: { '_Summary.md': { filename: '_Summary.md', raw_url: 'https://some_url' } },
          git_pull_url: 'https://gist.github.com/gistid.git'
        )
      end
    end
  end

  describe '.from_api_response' do
    let(:response) do
      {
        id: '1',
        description: 'Gist title',
        public: true,
        created_at: '2022-04-26 18:30:53 UTC',
        updated_at: '2022-04-26 18:30:53 UTC',
        files: { '_Summary.md': { filename: '_Summary.md', raw_url: 'https://some_url' } },
        git_pull_url: 'https://gist.github.com/gistid.git'
      }
    end

    it_behaves_like 'a Gist' do
      let(:gist) { described_class.from_api_response(response) }
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'a Gist' do
      let(:hash) do
        {
          'id' => '1',
          'description' => 'Gist title',
          'is_public' => true,
          'files' => { '_Summary.md': { filename: '_Summary.md', raw_url: 'https://some_url' } },
          'git_pull_url' => 'https://gist.github.com/gistid.git'
        }
      end

      let(:gist) { described_class.from_json_hash(hash) }
    end
  end

  describe '#truncated_title' do
    it 'truncates the title to 255 characters' do
      object = described_class.new(description: 'm' * 300)

      expect(object.truncated_title.length).to eq(255)
    end

    it 'does not truncate the title if it is shorter than 255 characters' do
      object = described_class.new(description: 'foo')

      expect(object.truncated_title).to eq('foo')
    end
  end

  describe '#github_identifiers' do
    it 'returns a hash with needed identifiers' do
      github_identifiers = { id: 1 }
      gist = described_class.new(github_identifiers.merge(something_else: '_something_else_'))

      expect(gist.github_identifiers).to eq(github_identifiers)
    end
  end

  describe '#visibility_level' do
    it 'returns 20 when public' do
      visibility = { is_public: true }
      gist = described_class.new(visibility.merge(something_else: '_something_else_'))

      expect(gist.visibility_level).to eq(20)
    end

    it 'returns 0 when private' do
      visibility = { is_public: false }
      gist = described_class.new(visibility.merge(something_else: '_something_else_'))

      expect(gist.visibility_level).to eq(0)
    end
  end

  describe '#first_file' do
    let(:http_response) { instance_double('HTTParty::Response', body: 'File content') }

    before do
      allow(Gitlab::HTTP).to receive(:try_get).and_return(http_response)
    end

    it 'returns a hash with needed identifiers' do
      files = { files: { '_Summary.md': { filename: '_Summary.md', raw_url: 'https://some_url' } } }
      gist = described_class.new(files.merge(something_else: '_something_else_'))

      expect(gist.first_file).to eq(file_name: '_Summary.md', file_content: 'File content')
    end
  end
end
