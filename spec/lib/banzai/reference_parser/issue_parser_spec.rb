require 'spec_helper'

describe Banzai::ReferenceParser::IssueParser, lib: true do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:parser) { described_class.new(project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#user_can_see_reference?' do
    context 'when the link has a data-issue attribute' do
      before do
        link['data-issue'] = issue.id.to_s
      end

      it 'returns true when the user can read the issue' do
        expect(Ability.abilities).to receive(:allowed?).
          with(user, :read_issue, issue).
          and_return(true)

        expect(parser.user_can_see_reference?(user, link)).to eq(true)
      end

      it 'returns false when the user can not read the issue' do
        expect(Ability.abilities).to receive(:allowed?).
          with(user, :read_issue, issue).
          and_return(false)

        expect(parser.user_can_see_reference?(user, link)).to eq(false)
      end
    end

    context 'when the link does not have a data-issue attribute' do
      it 'returns false' do
        expect(parser.user_can_see_reference?(user, link)).to eq(false)
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
end
