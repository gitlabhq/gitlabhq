# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablePolicy, models: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:issue) { create(:issue, project: project) }
  let(:policies) { described_class.new(user, issue) }

  describe '#rules' do
    context 'when user is author of issuable' do
      let(:merge_request) { create(:merge_request, source_project: project, author: user) }
      let(:policies) { described_class.new(user, merge_request) }

      context 'when user is able to read project' do
        it 'enables user to read and update issuables' do
          expect(policies).to be_allowed(:read_issue, :update_issue, :reopen_issue, :read_merge_request, :update_merge_request, :reopen_merge_request)
        end
      end

      context 'when project is private' do
        let(:project) { create(:project, :private) }

        context 'when user belongs to the projects team' do
          it 'enables user to read and update issuables' do
            project.add_maintainer(user)

            expect(policies).to be_allowed(:read_issue, :update_issue, :reopen_issue, :read_merge_request, :update_merge_request, :reopen_merge_request)
          end
        end

        it 'disallows user from reading and updating issuables from that project' do
          expect(policies).to be_disallowed(:read_issue, :update_issue, :reopen_issue, :read_merge_request, :update_merge_request, :reopen_merge_request)
        end
      end
    end

    context 'when discussion is locked for the issuable' do
      let(:issue) { create(:issue, project: project, discussion_locked: true) }

      context 'when the user is not a project member' do
        it 'can not create a note nor award emojis' do
          expect(policies).to be_disallowed(:create_note, :award_emoji)
        end
      end

      context 'when the user is a project member' do
        before do
          project.add_guest(user)
        end

        it 'can create a note and award emojis' do
          expect(policies).to be_allowed(:create_note, :award_emoji)
        end
      end
    end
  end
end
