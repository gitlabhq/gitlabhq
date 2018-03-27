require 'spec_helper'

describe IssuablePolicy, models: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:issue) { create(:issue, project: project) }
  let(:policies) { described_class.new(user, issue) }

  describe '#rules' do
    context 'when discussion is locked for the issuable' do
      let(:issue) { create(:issue, project: project, discussion_locked: true) }

      context 'when the user is not a project member' do
        it 'can not create a note' do
          expect(policies).to be_disallowed(:create_note)
        end
      end

      context 'when the user is a project member' do
        before do
          project.add_guest(user)
        end

        it 'can create a note' do
          expect(policies).to be_allowed(:create_note)
        end
      end
    end
  end
end
