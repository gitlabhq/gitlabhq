# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::EmailParticipants, feature_category: :service_desk do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  let_it_be(:participant_1) do
    create(:issue_email_participant, issue: work_item, email: 'alice@example.com')
  end

  let_it_be(:participant_2) do
    create(:issue_email_participant, issue: work_item, email: 'bob@example.com')
  end

  shared_examples 'email participants endpoint' do
    it 'returns email participants with default fields', :aggregate_failures do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an(Array)
      expect(json_response.size).to eq(2)
      expect(json_response).to all(include('id', 'email'))
      expect(json_response).to all(satisfy { |item| item.keys.exclude?('created_at') })
      expect(json_response).to all(satisfy { |item| item.keys.exclude?('updated_at') })
    end

    it 'returns 401 when the user is not authenticated' do
      get api(api_request_path)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 404 when the work item does not exist' do
      get api(api_request_path.sub("/#{work_item.iid}/", "/#{non_existing_record_iid}/"), user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns forbidden when the feature flag is disabled' do
      stub_feature_flags(work_item_rest_api: false)

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'with optional fields requested' do
      it 'returns created_at when requested', :aggregate_failures do
        get api(api_request_path, user), params: { fields: 'created_at' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first).to include('id', 'email', 'created_at')
        expect(json_response.first).not_to include('updated_at')
      end

      it 'returns all fields when all are requested', :aggregate_failures do
        get api(api_request_path, user), params: { fields: 'created_at,updated_at' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first).to include('id', 'email', 'created_at', 'updated_at')
      end

      it 'ignores unknown field names', :aggregate_failures do
        get api(api_request_path, user), params: { fields: 'nonexistent,created_at' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first).to include('id', 'email', 'created_at')
        expect(json_response.first).not_to include('nonexistent')
      end
    end

    context 'with email obfuscation' do
      let_it_be(:guest_user) { create(:user) }

      before_all do
        project.add_guest(guest_user)
      end

      it 'obfuscates emails for users without read_external_emails permission', :aggregate_failures do
        get api(api_request_path, guest_user)

        expect(response).to have_gitlab_http_status(:ok)
        emails = json_response.pluck('email')
        expect(emails).to all(include('**'))
      end

      it 'returns full emails for users with read_external_emails permission', :aggregate_failures do
        get api(api_request_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        emails = json_response.pluck('email')
        expect(emails).to contain_exactly('alice@example.com', 'bob@example.com')
      end
    end

    context 'when work item type does not support email_participants widget' do
      let_it_be(:task_work_item) { create(:work_item, :task, project: project) }

      it 'returns 404' do
        path = api_request_path.sub("/#{work_item.iid}/", "/#{task_work_item.iid}/")

        get api(path, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with pagination', :aggregate_failures do
      it 'respects per_page parameter' do
        get api(api_request_path, user), params: { per_page: 1 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(1)
        expect(response.headers).to include('X-Next-Page')
      end

      it 'returns the second page' do
        get api(api_request_path, user), params: { per_page: 1, page: 2 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(1)
      end
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/email_participants' do
    let(:api_request_path) do
      "/projects/#{project.id}/-/work_items/#{work_item.iid}/email_participants"
    end

    it_behaves_like 'email participants endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not found when the user cannot read the work item' do
      other_user = create(:user)

      get api(api_request_path, other_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'does not issue N+1 queries when more participants are added', :aggregate_failures do
      # Warmup to settle lazy writes
      get api(api_request_path, user)

      baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get api(api_request_path, user)
      end

      create(:issue_email_participant, issue: work_item, email: 'charlie@example.com')

      # Settle any first-touch costs
      get api(api_request_path, user)

      expect { get api(api_request_path, user) }.to issue_same_number_of_queries_as(baseline)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(3)
    end
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/email_participants' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/email_participants"
    end

    it_behaves_like 'email participants endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
