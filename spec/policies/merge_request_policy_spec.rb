# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPolicy do
  include ExternalAuthorizationServiceHelpers

  let(:guest) { create(:user) }
  let(:author) { create(:user) }
  let(:developer) { create(:user) }
  let(:non_team_member) { create(:user) }
  let(:project) { create(:project, :public) }

  def permissions(user, merge_request)
    described_class.new(user, merge_request)
  end

  before do
    project.add_guest(guest)
    project.add_guest(author)
    project.add_developer(developer)
  end

  mr_perms = %i[create_merge_request_in
                create_merge_request_from
                read_merge_request
                create_todo
                approve_merge_request
                create_note
                update_subscription].freeze

  shared_examples_for 'a denied user' do
    let(:perms) { permissions(subject, merge_request) }

    mr_perms.each do |thing|
      it "cannot #{thing}" do
        expect(perms).to be_disallowed(thing)
      end
    end
  end

  shared_examples_for 'a user with access' do
    let(:perms) { permissions(subject, merge_request) }

    mr_perms.each do |thing|
      it "can #{thing}" do
        expect(perms).to be_allowed(thing)
      end
    end
  end

  context 'when merge request is public' do
    context 'and user is anonymous' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: author) }

      subject { permissions(nil, merge_request) }

      it do
        is_expected.to be_disallowed(:create_todo, :update_subscription)
      end
    end
  end

  context 'when merge requests have been disabled' do
    let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: author) }

    before do
      project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
    end

    describe 'the author' do
      subject { author }

      it_behaves_like 'a denied user'
    end

    describe 'a guest' do
      subject { guest }

      it_behaves_like 'a denied user'
    end

    describe 'a developer' do
      subject { developer }

      it_behaves_like 'a denied user'
    end

    describe 'any other user' do
      subject { non_team_member }

      it_behaves_like 'a denied user'
    end
  end

  context 'when merge requests are private' do
    let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: author) }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
    end

    describe 'a non-team-member' do
      subject { non_team_member }

      it_behaves_like 'a denied user'
    end

    describe 'a developer' do
      subject { developer }

      it_behaves_like 'a user with access'
    end
  end

  context 'when merge request is unlocked' do
    let(:merge_request) { create(:merge_request, :closed, source_project: project, target_project: project, author: author) }

    it 'allows author to reopen merge request' do
      expect(permissions(author, merge_request)).to be_allowed(:reopen_merge_request)
    end

    it 'allows developer to reopen merge request' do
      expect(permissions(developer, merge_request)).to be_allowed(:reopen_merge_request)
    end

    it 'prevents guest from reopening merge request' do
      expect(permissions(guest, merge_request)).to be_disallowed(:reopen_merge_request)
    end
  end

  context 'when merge request is locked' do
    let(:merge_request_locked) { create(:merge_request, :closed, discussion_locked: true, source_project: project, target_project: project, author: author) }

    it 'prevents author from reopening merge request' do
      expect(permissions(author, merge_request_locked)).to be_disallowed(:reopen_merge_request)
    end

    it 'prevents developer from reopening merge request' do
      expect(permissions(developer, merge_request_locked)).to be_disallowed(:reopen_merge_request)
    end

    it 'prevents guests from reopening merge request' do
      expect(permissions(guest, merge_request_locked)).to be_disallowed(:reopen_merge_request)
    end

    context 'when the user is not a project member' do
      let(:user) { create(:user) }

      it 'cannot create a note' do
        expect(permissions(user, merge_request_locked)).to be_disallowed(:create_note)
      end
    end

    context 'when the user is project member, with at least guest access' do
      let(:user) { guest }

      it 'can create a note' do
        expect(permissions(user, merge_request_locked)).to be_allowed(:create_note)
      end
    end
  end

  context 'with external authorization enabled' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:policies) { described_class.new(user, merge_request) }

    before do
      enable_external_authorization_service_check
    end

    it 'can read the issue iid without accessing the external service' do
      expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect(policies).to be_allowed(:read_merge_request_iid)
    end
  end
end
