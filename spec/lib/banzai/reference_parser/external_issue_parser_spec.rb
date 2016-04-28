require 'spec_helper'

describe Banzai::ReferenceParser::ExternalIssueParser, lib: true do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:parser) { described_class.new(project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#referenced_by' do
    context 'when the link has a data-project attribute' do
      before do
        link['data-project'] = project.id.to_s
      end

      context 'when the link has a data-external-issue attribute' do
        it 'returns an Array of ExternalIssue instances' do
          link['data-external-issue'] = '123'

          refs = parser.referenced_by(link)

          expect(refs).to eq([ExternalIssue.new('123', project)])
        end
      end

      context 'when the link does not have a data-external-issue attribute' do
        it 'returns an empty Array' do
          expect(parser.referenced_by(link)).to eq([])
        end
      end
    end

    context 'when the link does not have a data-project attribute' do
      it 'returns an empty Array' do
        expect(parser.referenced_by(link)).to eq([])
      end
    end
  end
end
