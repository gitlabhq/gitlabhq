require 'spec_helper'

describe Banzai::ReferenceParser::MilestoneParser do
  include ReferenceParserHelpers

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  let(:milestone) { create(:milestone, project: project) }
  subject { described_class.new(Banzai::RenderContext.new(project, user)) }
  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before do
        link['data-milestone'] = milestone.id.to_s
      end

      it_behaves_like "referenced feature visibility", "issues", "merge_requests"
    end
  end

  describe '#referenced_by' do
    describe 'when the link has a data-milestone attribute' do
      context 'using an existing milestone ID' do
        it 'returns an Array of milestones' do
          link['data-milestone'] = milestone.id.to_s

          expect(subject.referenced_by([link])).to eq([milestone])
        end
      end

      context 'using a non-existing milestone ID' do
        it 'returns an empty Array' do
          link['data-milestone'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
