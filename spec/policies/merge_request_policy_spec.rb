require 'spec_helper'

describe MergeRequestPolicy do
  include ExternalAuthorizationServiceHelpers

  let(:guest) { create(:user) }
  let(:author) { create(:user) }
  let(:developer) { create(:user) }
  let(:project) { create(:project, :public) }

  def permissions(user, merge_request)
    described_class.new(user, merge_request)
  end

  before do
    project.add_guest(guest)
    project.add_guest(author)
    project.add_developer(developer)
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
