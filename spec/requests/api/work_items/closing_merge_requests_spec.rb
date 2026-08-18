# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::ClosingMergeRequests, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :private, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:other_merge_request) { create(:merge_request, source_project: project, source_branch: 'other') }

  let_it_be(:closing_mr) do
    create(:merge_requests_closing_issues, issue: work_item, merge_request: merge_request, from_mr_description: true)
  end

  let_it_be(:other_closing_mr) do
    create(:merge_requests_closing_issues, issue: work_item, merge_request: other_merge_request,
      from_mr_description: false)
  end

  let(:expected_total) { 2 }
  # MergeRequestBasic issues a few irreducible per-record queries; reuse the core /merge_requests
  # API threshold (see spec/requests/api/merge_requests_spec.rb).
  let(:n_plus_one_threshold) { 3 }

  before do
    stub_feature_flags(work_item_rest_api: user)
  end

  # Adds one more visible closing merge request so the shared N+1 example can assert that growing
  # the collection does not add per-row queries.
  def add_development_feature_record
    extra_mr = create(:merge_request, source_project: project, source_branch: "extra-#{SecureRandom.hex(4)}")
    create(:merge_requests_closing_issues, issue: work_item, merge_request: extra_mr)
  end

  shared_examples 'closing_merge_requests endpoint' do
    it_behaves_like 'a work item development feature endpoint'

    it 'returns the closing merge requests of the work item' do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(closing_mr.id, other_closing_mr.id)
      expect(json_response).to all(include('id', 'from_mr_description', 'merge_request'))
    end

    it 'exposes the from_mr_description flag and the merge request' do
      get api(api_request_path, user)

      row = json_response.find { |r| r['id'] == closing_mr.id }
      expect(row['from_mr_description']).to be(true)
      expect(row['merge_request']).to include('iid' => merge_request.iid, 'id' => merge_request.id)
    end

    it 'excludes closing merge requests the user cannot read' do
      inaccessible_project = create(:project, :repository, :private)
      inaccessible_project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      inaccessible_mr = create(:merge_request, source_project: inaccessible_project)
      create(:merge_requests_closing_issues, issue: work_item, merge_request: inaccessible_mr)

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(closing_mr.id, other_closing_mr.id)
    end

    # A merge request in a different project can close this work item (cross-project closing). It must
    # be returned when the user can read it: visibility is filtered per merge request, not by the work
    # item's project, matching the GraphQL read_merge_request_closing_issue policy.
    it 'includes cross-project closing merge requests the user can read' do
      other_project = create(:project, :repository, :private, reporters: user)
      cross_project_mr = create(:merge_request, source_project: other_project)
      cross_project_closing_mr = create(:merge_requests_closing_issues, issue: work_item,
        merge_request: cross_project_mr)

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id'))
        .to contain_exactly(closing_mr.id, other_closing_mr.id, cross_project_closing_mr.id)
      expect(response.headers['X-Total']).to eq('3')
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/closing_merge_requests' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/closing_merge_requests" }

    it_behaves_like 'closing_merge_requests endpoint'

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

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/closing_merge_requests' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items" \
        "/#{work_item.iid}/closing_merge_requests"
    end

    it_behaves_like 'closing_merge_requests endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
