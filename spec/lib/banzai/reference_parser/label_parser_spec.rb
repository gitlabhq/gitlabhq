require 'spec_helper'

describe Banzai::ReferenceParser::LabelParser, lib: true do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:label) { create(:label, project: project) }
  let(:parser) { described_class.new(project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#referenced_by' do
    describe 'when the link has a data-label attribute' do
      context 'using an existing label ID' do
        it 'returns an Array of labels' do
          link['data-label'] = label.id.to_s

          expect(parser.referenced_by([link])).to eq([label])
        end
      end

      context 'using a non-existing label ID' do
        it 'returns an empty Array' do
          link['data-label'] = ''

          expect(parser.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
