# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablePolicy, :models do
  let_it_be(:user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:planner) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:issue) { create(:issue, project: project) }
  let(:policies) { described_class.new(user, issue) }

  before do
    project.add_developer(developer)
    project.add_guest(guest)
    project.add_planner(planner)
    project.add_reporter(reporter)
  end

  def permissions(user, issuable)
    described_class.new(user, issuable)
  end

  describe '#rules' do
    context 'when user is author of issuable' do
      let(:merge_request) { create(:merge_request, source_project: project, author: user) }
      let(:policies) { described_class.new(user, merge_request) }

      it 'allows resolving notes' do
        expect(policies).to be_allowed(:resolve_note)
      end

      it 'does not allow reading internal notes' do
        expect(policies).to be_disallowed(:read_internal_note)
      end

      context 'when user is able to read project' do
        it 'enables user to read and update issuables' do
          expect(policies).to be_allowed(:read_issue, :update_issue, :reopen_issue, :read_merge_request, :update_merge_request, :reopen_merge_request)
        end
      end

      context 'Timeline events' do
        it 'allows non-members to read time line events' do
          expect(permissions(guest, issue)).to be_allowed(:read_incident_management_timeline_event)
        end

        it 'disallows planners from managing timeline events' do
          expect(permissions(planner, issue)).to be_disallowed(:admin_incident_management_timeline_event)
        end

        it 'disallows reporters from managing timeline events' do
          expect(permissions(reporter, issue)).to be_disallowed(:admin_incident_management_timeline_event)
        end

        it 'allows developers to manage timeline events' do
          expect(permissions(developer, issue)).to be_allowed(:admin_incident_management_timeline_event)
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

        context 'Timeline events' do
          it 'disallows non-members from reading timeline events' do
            expect(permissions(user, issue)).to be_disallowed(:read_incident_management_timeline_event)
          end

          it 'allows guests to read time line events' do
            expect(permissions(guest, issue)).to be_allowed(:read_incident_management_timeline_event)
          end

          it 'disallows planners from managing timeline events' do
            expect(permissions(planner, issue)).to be_disallowed(:admin_incident_management_timeline_event)
          end

          it 'disallows reporters from managing timeline events' do
            expect(permissions(reporter, issue)).to be_disallowed(:admin_incident_management_timeline_event)
          end

          it 'allows developers to manage timeline events' do
            expect(permissions(developer, issue)).to be_allowed(:admin_incident_management_timeline_event)
          end
        end
      end
    end

    context 'when user is assignee of issuable' do
      let(:issue) { create(:issue, project: project, assignees: [user]) }
      let(:policies) { described_class.new(user, issue) }

      it 'does not allow reading internal notes' do
        expect(policies).to be_disallowed(:read_internal_note)
      end
    end

    context 'when discussion is locked for the issuable' do
      let(:issue) { create(:issue, project: project, discussion_locked: true) }

      context 'when the user is not a project member' do
        it 'can not create a note nor award emojis' do
          expect(policies).to be_disallowed(:create_note, :award_emoji)
        end

        it 'does not allow resolving note' do
          expect(policies).to be_disallowed(:resolve_note)
        end
      end

      context 'when the user is a project member' do
        before do
          project.add_developer(user)
        end

        it 'can create a note and award emojis' do
          expect(policies).to be_allowed(:create_note, :award_emoji)
        end

        it 'allows resolving notes' do
          expect(policies).to be_allowed(:resolve_note)
        end
      end
    end

    context 'when user is anonymous' do
      it 'does not allow timelogs creation' do
        expect(permissions(nil, issue)).to be_disallowed(:create_timelog)
      end
    end

    context 'when user is not a member of the project' do
      it 'does not allow timelogs creation' do
        expect(policies).to be_disallowed(:create_timelog)
      end
    end

    context 'when user is not a member of the project but the author of the issuable' do
      let(:issue) { create(:issue, project: project, author: user) }

      it 'does not allow timelogs creation' do
        expect(policies).to be_disallowed(:create_timelog)
      end

      it 'does not allow reading internal notes' do
        expect(permissions(guest, issue)).to be_disallowed(:read_internal_note)
      end
    end

    context 'when user is a guest member of the project' do
      it 'does not allow timelogs creation' do
        expect(permissions(guest, issue)).to be_disallowed(:create_timelog)
      end

      it 'does not allow reading internal notes' do
        expect(permissions(guest, issue)).to be_disallowed(:read_internal_note)
      end
    end

    context 'when user is a guest member of the project and the author of the issuable' do
      let(:issue) { create(:issue, project: project, author: guest) }

      it 'does not allow timelogs creation' do
        expect(permissions(guest, issue)).to be_disallowed(:create_timelog)
      end
    end

    context 'when user is at planner of the project' do
      it 'allows timelogs creation' do
        expect(permissions(planner, issue)).to be_allowed(:create_timelog)
      end

      it 'allows reading internal notes' do
        expect(permissions(planner, issue)).to be_allowed(:read_internal_note)
      end
    end

    context 'when user is at least reporter of the project' do
      it 'allows timelogs creation' do
        expect(permissions(reporter, issue)).to be_allowed(:create_timelog)
      end

      it 'allows reading internal notes' do
        expect(permissions(reporter, issue)).to be_allowed(:read_internal_note)
      end
    end

    context 'when subject is a Merge Request' do
      let(:issuable) { create(:merge_request) }
      let(:policy) { permissions(user, issuable) }

      before do
        allow(policy).to receive(:can?).with(:read_merge_request).and_return(can_read_merge_request)
      end

      context 'when can_read_merge_request is false' do
        let(:can_read_merge_request) { false }

        it 'does not allow :read_issuable' do
          expect(policy).not_to be_allowed(:read_issuable)
          expect(policy).not_to be_allowed(:read_issuable_participables)
        end
      end

      context 'when can_read_merge_request is true' do
        let(:can_read_merge_request) { true }

        it 'allows :read_issuable' do
          expect(policy).to be_allowed(:read_issuable)
          expect(policy).to be_allowed(:read_issuable_participables)
        end
      end
    end

    context 'when subject is an Issue' do
      let(:issuable) { create(:issue) }
      let(:policy) { permissions(user, issuable) }

      before do
        allow(policy).to receive(:can?).with(:read_issue).and_return(can_read_issue)
      end

      context 'when can_read_issue is false' do
        let(:can_read_issue) { false }

        it 'does not allow :read_issuable' do
          expect(policy).not_to be_allowed(:read_issuable)
          expect(policy).not_to be_allowed(:read_issuable_participables)
        end
      end

      context 'when can_read_issue is true' do
        let(:can_read_issue) { true }

        it 'allows :read_issuable' do
          expect(policy).to be_allowed(:read_issuable)
          expect(policy).to be_allowed(:read_issuable_participables)
        end
      end
    end
  end
end
