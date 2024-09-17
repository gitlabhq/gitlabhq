# frozen_string_literal: true

RSpec.shared_examples 'access restricted confidential issues' do |document_type: :issue|
  let(:query) { 'issue' }
  let(:author) { create(:user) }
  let(:assignee) { create(:user) }
  let(:project) { create(:project, :internal) }

  let!(:issue) {  create(document_type, project: project, title: 'Issue 1') }
  let!(:security_issue_1) {  create(document_type, :confidential, project: project, title: 'Security issue 1', author: author) }
  let!(:security_issue_2) {  create(document_type, :confidential, title: 'Security issue 2', project: project, assignees: [assignee]) }

  subject(:objects) do
    described_class.new(user, query, project: project).objects('issues')
  end

  context 'when the user is non-member' do
    let(:user) { create(:user) }

    it 'does not list project confidential issues for non project members' do
      expect(objects).to contain_exactly(issue)
      expect(results.limited_issues_count).to eq 1
    end
  end

  context 'when the member is guest' do
    let(:user) do
      create(:user) { |guest| project.add_guest(guest) }
    end

    it 'does not list project confidential issues for project members with guest role' do
      expect(objects).to contain_exactly(issue)
      expect(results.limited_issues_count).to eq 1
    end
  end

  context 'when the user is the author' do
    let(:user) { author }

    it 'lists project confidential issues' do
      expect(objects).to contain_exactly(issue, security_issue_1)
      expect(results.limited_issues_count).to eq 2
    end
  end

  context 'when the user is the assignee' do
    let(:user) { assignee }

    it 'lists project confidential issues for assignee' do
      expect(objects).to contain_exactly(issue, security_issue_2)
      expect(results.limited_issues_count).to eq 2
    end
  end

  context 'when the user is a developer' do
    let(:user) do
      create(:user) { |user| project.add_developer(user) }
    end

    it 'lists project confidential issues' do
      expect(objects).to contain_exactly(issue, security_issue_1, security_issue_2)
      expect(results.limited_issues_count).to eq 3
    end
  end

  context 'when the user is admin', :request_store do
    let(:user) { create(:user, admin: true) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'lists all project issues' do
        expect(objects).to contain_exactly(issue, security_issue_1, security_issue_2)
      end
    end

    context 'when admin mode is disabled' do
      it 'does not list project confidential issues' do
        expect(objects).to contain_exactly(issue)
        expect(results.limited_issues_count).to eq 1
      end
    end
  end
end
