require 'spec_helper'

describe Banzai::ReferenceParser::MilestoneParser, lib: true do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:milestone) { create(:milestone, project: project) }
  let(:parser) { described_class.new(project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#referenced_by' do
    describe 'when the link has a data-milestone attribute' do
      context 'using an existing milestone ID' do
        it 'returns an Array of milestones' do
          link['data-milestone'] = milestone.id.to_s

          expect(parser.referenced_by([link])).to eq([milestone])
        end
      end

      context 'using a non-existing milestone ID' do
        it 'returns an empty Array' do
          link['data-milestone'] = ''

          expect(parser.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
