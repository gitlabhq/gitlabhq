require 'spec_helper'

describe Banzai::ReferenceParser::LabelParser, lib: true do
  include ReferenceParserHelpers

  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:label) { create(:label, subject: project) }
  subject { described_class.new(project, user) }
  let(:link) { empty_html_link }

  describe '#referenced_by' do
    describe 'when the link has a data-label attribute' do
      context 'using an existing label ID' do
        it 'returns an Array of labels' do
          link['data-label'] = label.id.to_s

          expect(subject.referenced_by([link])).to eq([label])
        end
      end

      context 'using a non-existing label ID' do
        it 'returns an empty Array' do
          link['data-label'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
