# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::AwardEmoji, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  let_it_be(:thumbs_up) { create(:award_emoji, awardable: work_item, user: user, name: 'thumbsup') }
  let_it_be(:rocket) { create(:award_emoji, awardable: work_item, user: user, name: 'rocket') }

  before do
    stub_feature_flags(work_item_rest_api: user)
  end

  shared_examples 'award_emoji endpoint' do
    it 'returns emoji reactions on the work item' do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(thumbs_up.id, rocket.id)
      expect(json_response).to all(include('id', 'name', 'user', 'awardable_id', 'awardable_type', 'url'))
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

    it 'paginates the response' do
      get api(api_request_path, user), params: { per_page: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(1)
      expect(response.headers['X-Total']).to eq('2')
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/award_emoji' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/award_emoji" }

    it_behaves_like 'award_emoji endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      other_user = create(:user)

      get api(api_request_path, other_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/award_emoji' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/award_emoji"
    end

    it_behaves_like 'award_emoji endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
