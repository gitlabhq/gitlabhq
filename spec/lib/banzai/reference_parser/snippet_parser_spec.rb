require 'spec_helper'

describe Banzai::ReferenceParser::SnippetParser, lib: true do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:snippet) { create(:snippet, project: project) }
  let(:parser) { described_class.new(project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#referenced_by' do
    it 'returns an Array of Banzai::LazyReference instances' do
      link['data-snippet'] = snippet.id.to_s

      refs = parser.referenced_by(link)

      expect(refs).to be_an_instance_of(Array)

      expect(refs[0]).to be_an_instance_of(Banzai::LazyReference)
      expect(refs[0].klass).to eq(Snippet)
      expect(refs[0].ids).to eq([snippet.id])
    end
  end
end
