require 'spec_helper'

describe Banzai::ReferenceParser::IssueParser, lib: true do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:parser) { described_class.new(project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before do
        link['data-issue'] = issue.id.to_s
      end

      it 'returns the nodes when the user can read the issue' do
        expect(Ability.abilities).to receive(:allowed?).
          with(user, :read_issue, issue).
          and_return(true)

        expect(parser.nodes_visible_to_user(user, [link])).to eq([link])
      end

      it 'returns an empty Array when the user can not read the issue' do
        expect(Ability.abilities).to receive(:allowed?).
          with(user, :read_issue, issue).
          and_return(false)

        expect(parser.nodes_visible_to_user(user, [link])).to eq([])
      end
    end

    context 'when the link does not have a data-issue attribute' do
      it 'returns an empty Array' do
        expect(parser.nodes_visible_to_user(user, [link])).to eq([])
      end
    end
  end

  describe '#referenced_by' do
    describe 'when the link has a data-issue attribute' do
      context 'using an existing issue ID' do
        it 'returns an Array of issues' do
          link['data-issue'] = issue.id.to_s

          expect(parser.referenced_by([link])).to eq([issue])
        end
      end

      context 'using a non-existing issue ID' do
        it 'returns an empty Array' do
          link['data-issue'] = ''

          expect(parser.referenced_by([link])).to eq([])
        end
      end
    end
  end

  describe '#issues_for_nodes' do
    it 'returns a Hash containing the issues for a list of nodes' do
      link['data-issue'] = issue.id.to_s
      nodes = [link]

      expect(parser.issues_for_nodes(nodes)).to eq({issue.id => issue})
    end
  end
end
