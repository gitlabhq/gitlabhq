# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Timeline Events', feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project) }

  describe 'POST /preview_markdown' do
    let(:timeline_text) { "timeline text with image ![img](img/src.png) and reference #{incident.to_reference}" }

    context 'when authorized' do
      let(:expected_img) do
        '<a class="with-attachment-icon" href="img/src.png" target="_blank" rel="noopener noreferrer">img</a>'
      end

      let(:expected_reference) do
        "<a href=\"/#{project.full_path}/-/issues/#{incident.iid}\" data-reference-type=\"issue\" " \
          "data-original=\"##{incident.iid}\" data-link=\"false\" data-link-reference=\"false\" " \
          "data-issue=\"#{incident.id}\" data-project=\"#{project.id}\" data-iid=\"#{incident.iid}\" " \
          "data-namespace-path=\"#{project.full_path}\" data-project-path=\"#{project.full_path}\" " \
          "data-issue-type=\"incident\" data-container=\"body\" data-placement=\"top\" " \
          "title=\"#{incident.title}\" class=\"gfm gfm-issue\">##{incident.iid}</a>"
      end

      let(:expected_body) do
        "<p>timeline text with image #{expected_img} and reference #{expected_reference}</p>"
      end

      before do
        project.add_developer(user)
        login_as(user)
      end

      it 'renders JSON in a correct format' do
        post preview_markdown_project_incident_management_timeline_events_path(project, format: :json),
          params: { text: timeline_text }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({
          body: expected_body,
          references: {
            commands: '',
            suggestions: [],
            users: []
          }
        }.as_json)
      end
    end

    context 'when not authorized' do
      it 'returns 302' do
        post preview_markdown_project_incident_management_timeline_events_path(project, format: :json),
          params: { text: timeline_text }

        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end
end
