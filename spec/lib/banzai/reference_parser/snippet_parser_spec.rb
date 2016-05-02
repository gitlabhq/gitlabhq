require 'spec_helper'

describe Banzai::ReferenceParser::SnippetParser, lib: true do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:snippet) { create(:snippet, project: project) }
  let(:parser) { described_class.new(project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#referenced_by' do
    describe 'when the link has a data-snippet attribute' do
      context 'using an existing snippet ID' do
        it 'returns an Array of snippets' do
          link['data-snippet'] = snippet.id.to_s

          expect(parser.referenced_by([link])).to eq([snippet])
        end
      end

      context 'using a non-existing snippet ID' do
        it 'returns an empty Array' do
          link['data-snippet'] = ''

          expect(parser.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
