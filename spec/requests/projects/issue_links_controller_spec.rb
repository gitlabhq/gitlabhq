require 'rails_helper'

describe Projects::IssueLinksController do
  let(:user) { create :user }
  let(:project) { create(:project_empty_repo) }
  let(:issue) { create :issue, project: project }

  before do
    allow_any_instance_of(License).to receive(:feature_available?) { false }
    allow_any_instance_of(License).to receive(:feature_available?).with(:related_issues) { true }
  end

  describe 'GET /*namespace_id/:project_id/issues/:issue_id/links' do
    let(:issue_b) { create :issue, project: project }
    let!(:issue_link) { create :issue_link, source: issue, target: issue_b }

    before do
      project.team << [user, :guest]
      login_as user
    end

    subject do
      get namespace_project_issue_links_path(namespace_id: issue.project.namespace,
                                             project_id: issue.project,
                                             issue_id: issue,
                                             format: :json)
    end

    it 'returns JSON response' do
      list_service_response = IssueLinks::ListService.new(issue, user).execute

      subject

      expect(response).to have_http_status(200)
      expect(json_response).to eq(list_service_response.as_json)
    end
  end

  describe 'POST /*namespace_id/:project_id/issues/:issue_id/links' do
    let(:issue_b) { create :issue, project: project }
    let(:issue_references) { [issue_b.to_reference] }
    let(:user_role) { :developer }

    before do
      project.team << [user, user_role]
      login_as user
    end

    subject do
      post namespace_project_issue_links_path(namespace_id: issue.project.namespace,
                                              project_id: issue.project,
                                              issue_id: issue,
                                              issue_references: issue_references,
                                              format: :json)
    end

    context 'with success' do
      it 'returns success JSON' do
        subject

        list_service_response = IssueLinks::ListService.new(issue, user).execute

        expect(response).to have_http_status(200)
        expect(json_response['result']).to eq('status' => 'success')
        expect(json_response['issues']).to eq(list_service_response.as_json)
      end
    end

    context 'with failure' do
      context 'when unauthorized' do
        let(:user_role) { :guest }

        it 'returns 403' do
          subject

          expect(response).to have_http_status(403)
        end
      end

      context 'when failing service result' do
        let(:issue_references) { ['#999'] }

        it 'returns failure JSON' do
          subject

          list_service_response = IssueLinks::ListService.new(issue, user).execute

          expect(response).to have_http_status(401)
          expect(json_response['result']).to eq('message' => 'No Issue found for given reference',
                                                'status' => 'error',
                                                'http_status' => 401)
          expect(json_response['issues']).to eq(list_service_response.as_json)
        end
      end
    end
  end

  describe 'DELETE /*namespace_id/:project_id/issues/:issue_id/link/:id' do
    let(:referenced_issue) { create :issue, project: project }
    let(:issue_link) { create :issue_link, target: referenced_issue }
    let(:current_project_user_role) { :developer }

    subject do
      delete namespace_project_issue_link_path(namespace_id: issue.project.namespace,
                                               project_id: issue.project,
                                               issue_id: issue,
                                               id: issue_link.id,
                                               format: :json)
    end

    before do
      project.team << [user, current_project_user_role]
      login_as user
    end

    context 'when unauthorized' do
      context 'when no authorization on current project' do
        let(:current_project_user_role) { :guest }

        it 'returns 403' do
          subject

          expect(response).to have_http_status(403)
        end
      end

      context 'when no authorization on the related issue project' do
        # unauthorized project issue
        let(:referenced_issue) { create :issue }
        let(:current_project_user_role) { :developer }

        it 'returns 403' do
          subject

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'when authorized' do
      let(:current_project_user_role) { :developer }

      it 'returns success JSON' do
        subject

        list_service_response = IssueLinks::ListService.new(issue, user).execute

        expect(json_response['result']).to eq('message' => 'Relation was removed', 'status' => 'success')
        expect(json_response['issues']).to eq(list_service_response.as_json)
      end
    end
  end
end
