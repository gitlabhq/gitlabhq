# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners::Parser, feature_category: :code_review_workflow do
  subject(:parser) { described_class.new(blob_data) }

  describe '#entries' do
    let(:blob_data) do
      <<~CODEOWNERS
        # Global fallback
        * @everyone

        # Ruby files
        *.rb @backend-team

        [Frontend]
        *.vue @frontend-team @alice

        ^[Optional]
        docs/ @docs-team

        /lib/gitlab/code_owners/ @platform
      CODEOWNERS
    end

    it 'parses the correct number of entries' do
      expect(parser.entries.size).to eq(5)
    end

    it 'sets the wildcard entry' do
      entry = parser.entries[0]
      expect(entry.pattern).to eq('*')
      expect(entry.owners).to eq(['@everyone'])
      expect(entry.section).to eq('codeowners')
      expect(entry.optional).to be(false)
    end

    it 'parses a section header' do
      entry = parser.entries[2]
      expect(entry.section).to eq('Frontend')
      expect(entry.owners).to contain_exactly('@frontend-team', '@alice')
    end

    it 'parses an optional section' do
      entry = parser.entries[3]
      expect(entry.section).to eq('Optional')
      expect(entry.optional).to be(true)
    end

    context 'with empty or comment lines' do
      let(:blob_data) { "# comment\n\n*.rb @dev\n" }

      it 'skips them' do
        expect(parser.entries.size).to eq(1)
      end
    end
  end

  describe '#owners_for_path' do
    let(:blob_data) do
      <<~CODEOWNERS
        * @fallback
        *.rb @ruby-owner
        /app/models/ @models-team
        /lib/gitlab/code_owners/ @platform
      CODEOWNERS
    end

    it 'returns the fallback owner when nothing specific matches' do
      expect(parser.owners_for_path('/random/file.txt')).to eq(['@fallback'])
    end

    it 'matches by extension' do
      expect(parser.owners_for_path('/some/path/foo.rb')).to eq(['@ruby-owner'])
    end

    it 'matches a directory pattern' do
      expect(parser.owners_for_path('/app/models/user.rb')).to eq(['@models-team'])
    end

    it 'matches a specific subdirectory' do
      expect(parser.owners_for_path('/lib/gitlab/code_owners/parser.rb')).to eq(['@platform'])
    end

    it 'returns [] when no CODEOWNERS file has entries' do
      parser = described_class.new('')
      expect(parser.owners_for_path('/anything.rb')).to eq([])
    end

    it 'handles paths without a leading slash' do
      expect(parser.owners_for_path('some/path/foo.rb')).to eq(['@ruby-owner'])
    end
  end

  describe 'last-match-wins precedence' do
    let(:blob_data) do
      <<~CODEOWNERS
        * @first
        *.rb @second
        /app/ @third
        /app/models/ @fourth
      CODEOWNERS
    end

    it 'uses the last matching rule' do
      expect(parser.owners_for_path('/app/models/user.rb')).to eq(['@fourth'])
    end
  end
end
