# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEntity do
  include Gitlab::Routing.url_helpers

  let(:project)  { create(:project) }
  let(:resource) { create(:issue, project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  describe 'web_url' do
    context 'when issue is of type task' do
      let(:resource) { create(:issue, :task, project: project) }

      # This was already a path and not a url when the work items change was introduced
      it 'has a work item path with iid' do
        expect(subject[:web_url]).to eq(project_work_item_path(project, resource.iid))
      end
    end
  end

  describe 'type' do
    it 'has an issue type' do
      expect(subject[:type]).to eq('ISSUE')
    end
  end

  it 'has Issuable attributes' do
    expect(subject).to include(
      :id, :iid, :author_id, :description, :lock_version, :milestone_id,
      :title, :updated_by_id, :created_at, :updated_at, :milestone, :labels
    )
  end

  it 'has time estimation attributes' do
    expect(subject).to include(:time_estimate, :total_time_spent, :human_time_estimate, :human_total_time_spent)
  end

  describe 'current_user' do
    it 'has the exprected permissions' do
      expect(subject[:current_user]).to include(
        :can_create_note, :can_update, :can_set_issue_metadata, :can_award_emoji
      )
    end
  end

  context 'when issue got moved' do
    let(:public_project) { create(:project, :public) }
    let(:member) { create(:user) }
    let(:non_member) { create(:user) }
    let(:issue) { create(:issue, project: public_project) }

    before do
      project.add_developer(member)
      public_project.add_developer(member)
      Issues::MoveService.new(container: public_project, current_user: member).execute(issue, project)
    end

    context 'when user cannot read target project' do
      it 'does not return moved_to_id' do
        request = double('request', current_user: non_member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:moved_to_id]).to be_nil
      end
    end

    context 'when user can read target project' do
      it 'returns moved moved_to_id' do
        request = double('request', current_user: member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:moved_to_id]).to eq(issue.moved_to_id)
      end
    end
  end

  context 'when issue got duplicated' do
    let(:private_project) { create(:project, :private) }
    let(:member) { create(:user) }
    let(:issue) { create(:issue, project: project) }
    let(:new_issue) { create(:issue, project: private_project) }

    before do
      Issues::DuplicateService
        .new(container: project, current_user: member)
        .execute(issue, new_issue)
    end

    context 'when user cannot read new issue' do
      let(:non_member) { create(:user) }

      it 'does not return duplicated_to_id' do
        request = double('request', current_user: non_member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:duplicated_to_id]).to be_nil
      end
    end

    context 'when user can read target project' do
      before do
        project.add_developer(member)
        private_project.add_developer(member)
      end

      it 'returns duplicated duplicated_to_id' do
        request = double('request', current_user: member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:duplicated_to_id]).to eq(issue.duplicated_to_id)
      end
    end
  end

  context 'when issuable in active or archived project' do
    before do
      project.add_developer(user)
    end

    context 'when project is active' do
      it 'returns archived false' do
        expect(subject[:is_project_archived]).to eq(false)
      end

      it 'returns nil for archived project doc' do
        response = described_class.new(resource, request: request).as_json

        expect(response[:archived_project_docs_path]).to be nil
      end
    end

    context 'when project is archived' do
      before do
        project.update!(archived: true)
      end

      it 'returns archived true' do
        expect(subject[:is_project_archived]).to eq(true)
      end

      it 'returns archived project doc' do
        expect(subject[:archived_project_docs_path]).to eq(
          '/help/user/project/working_with_projects.md#delete-a-project'
        )
      end
    end
  end

  it_behaves_like 'issuable entity current_user properties'

  context 'when issue has email participants' do
    let(:obfuscated_email) { 'an*****@e*****.c**' }
    let(:email) { 'any@email.com' }

    before do
      resource.issue_email_participants.create!(email: email)
    end

    context 'with anonymous user' do
      it 'returns obfuscated email participants email' do
        request = double('request', current_user: nil)

        response = described_class.new(resource, request: request).as_json
        expect(response[:issue_email_participants]).to eq([{ email: obfuscated_email }])
      end
    end

    context 'with signed in user' do
      context 'when user has no role in project' do
        it 'returns obfuscated email participants email' do
          expect(subject[:issue_email_participants]).to eq([{ email: obfuscated_email }])
        end
      end

      context 'when user has guest role in project' do
        let(:member) { create(:user) }

        before do
          project.add_guest(member)
        end

        it 'returns obfuscated email participants email' do
          request = double('request', current_user: member)

          response = described_class.new(resource, request: request).as_json
          expect(response[:issue_email_participants]).to eq([{ email: obfuscated_email }])
        end
      end

      context 'when user has (at least) reporter role in project' do
        let(:member) { create(:user) }

        before do
          project.add_reporter(member)
        end

        it 'returns full email participants email' do
          request = double('request', current_user: member)

          response = described_class.new(resource, request: request).as_json
          expect(response[:issue_email_participants]).to eq([{ email: email }])
        end
      end
    end
  end
end
