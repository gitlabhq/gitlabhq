# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::RelatedMergeRequests, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :private, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  let_it_be(:referenced_mr) do
    create(:merge_request, source_project: project, source_branch: 'csv').tap do |merge_request|
      create(:note, :system, project: project, noteable: work_item, author: user,
        note: merge_request.to_reference(full: true))
    end
  end

  let_it_be(:other_mr) do
    create(:merge_request, source_project: project, source_branch: 'improve/awesome').tap do |merge_request|
      create(:note, :system, project: project, noteable: work_item, author: user,
        note: merge_request.to_reference(full: true))
    end
  end

  let(:expected_total) { 2 }
  # MergeRequestBasic issues a few irreducible per-record queries; reuse the core /merge_requests
  # API threshold (see spec/requests/api/merge_requests_spec.rb).
  let(:n_plus_one_threshold) { 3 }

  before do
    stub_feature_flags(work_item_rest_api: user)
  end

  # Adds one more referenced merge request so the shared N+1 example can assert that growing the
  # collection does not add per-record queries.
  def add_development_feature_record
    mr = create(:merge_request, source_project: project, source_branch: "extra-#{SecureRandom.hex(4)}")
    create(:note, :system, project: project, noteable: work_item, author: user,
      note: mr.to_reference(full: true))
  end

  shared_examples 'related_merge_requests endpoint' do
    it_behaves_like 'a work item development feature endpoint'

    it 'returns the merge requests related to the work item' do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(referenced_mr.id, other_mr.id)
      expect(json_response).to all(include('id', 'iid', 'title', 'state'))
    end

    it 'matches Issues::ReferencedMergeRequestsService (parity by construction)' do
      expected = ::Issues::ReferencedMergeRequestsService
        .new(container: project, current_user: user)
        .referenced_merge_requests(work_item)

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to match_array(expected.map(&:id))
    end

    it 'orders merge requests by iid rather than by reference discovery order' do
      lower_iid_mr = create(:merge_request, source_project: project, source_branch: "aaa-#{SecureRandom.hex(4)}")
      higher_iid_mr = create(:merge_request, source_project: project, source_branch: "bbb-#{SecureRandom.hex(4)}")

      [higher_iid_mr, lower_iid_mr].each do |mr|
        create(:note, :system, project: project, noteable: work_item, author: user,
          note: mr.to_reference(full: true))
      end

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('iid'))
        .to eq([referenced_mr.iid, other_mr.iid, lower_iid_mr.iid, higher_iid_mr.iid])
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/related_merge_requests' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/related_merge_requests" }

    it_behaves_like 'related_merge_requests endpoint'

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

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/related_merge_requests' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/" \
        "related_merge_requests"
    end

    it_behaves_like 'related_merge_requests endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
