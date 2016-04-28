require 'spec_helper'

describe Banzai::ReferenceParser::MilestoneParser, lib: true do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:milestone) { create(:milestone, project: project) }
  let(:parser) { described_class.new(project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#referenced_by' do
    it 'returns an Array of Banzai::LazyReference instances' do
      link['data-milestone'] = milestone.id.to_s

      refs = parser.referenced_by(link)

      expect(refs).to be_an_instance_of(Array)

      expect(refs[0]).to be_an_instance_of(Banzai::LazyReference)
      expect(refs[0].klass).to eq(Milestone)
      expect(refs[0].ids).to eq([milestone.id])
    end
  end
end
