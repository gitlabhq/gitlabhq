require 'spec_helper'

describe Banzai::ReferenceParser::SnippetParser, lib: true do
  include ReferenceParserHelpers

  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:snippet) { create(:snippet, project: project) }
  subject { described_class.new(project, user) }
  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before { link['data-snippet'] = snippet.id.to_s }

      it_behaves_like "referenced feature visibility", "snippets"
    end
  end

  describe '#referenced_by' do
    describe 'when the link has a data-snippet attribute' do
      context 'using an existing snippet ID' do
        it 'returns an Array of snippets' do
          link['data-snippet'] = snippet.id.to_s

          expect(subject.referenced_by([link])).to eq([snippet])
        end
      end

      context 'using a non-existing snippet ID' do
        it 'returns an empty Array' do
          link['data-snippet'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
