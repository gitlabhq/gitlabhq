# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::RelatedBranches, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  # :small_repo is enough here: the specs only branch off default_branch and never read seed-repo
  # content, and RelatedBranchesService only needs repository.exists?.
  let_it_be(:project) { create(:project, :small_repo, :private, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  let_it_be(:branch_name) { "#{work_item.iid}-related-branch" }
  let_it_be(:other_branch_name) { "#{work_item.iid}-another-branch" }

  let(:expected_total) { 2 }
  let(:n_plus_one_threshold) { 0 }
  # Git branch creation is not rolled back with the DB transaction, so the N+1 example's added
  # branches are collected here and dropped in the after hook to keep the baseline (2) stable.
  let(:extra_branches) { [] }

  before_all do
    project.repository.create_branch(branch_name, project.default_branch)
    project.repository.create_branch(other_branch_name, project.default_branch)
  end

  before do
    stub_feature_flags(work_item_rest_api: user)
  end

  after do
    extra_branches.each { |name| project.repository.delete_branch(name) }
  end

  # Adds one more related branch so the shared N+1 example can assert that growing the collection
  # does not add per-record queries.
  def add_development_feature_record
    create_related_branch("extra")
  end

  def create_related_branch(tag, with_pipeline: false)
    name = "#{work_item.iid}-#{tag}-#{SecureRandom.hex(4)}"
    extra_branches << name
    project.repository.create_branch(name, project.default_branch)

    if with_pipeline
      sha = project.repository.find_branch(name).dereferenced_target.sha
      create(:ci_pipeline, project: project, ref: name, sha: sha, status: :success)
    end

    name
  end

  shared_examples 'related_branches endpoint' do
    it_behaves_like 'a work item development feature endpoint'

    it 'returns related branches of the work item' do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('name')).to include(branch_name, other_branch_name)
      expect(json_response).to all(include('name', 'compare_path', 'pipeline_status'))
    end

    it 'orders branches by name so pagination is deterministic' do
      # Created last but sorts first, so a page built without sorting would not return it.
      first_by_name = "#{work_item.iid}-aaa-#{SecureRandom.hex(4)}"
      extra_branches << first_by_name
      project.repository.create_branch(first_by_name, project.default_branch)

      get api(api_request_path, user), params: { per_page: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('name')).to eq([first_by_name])
    end

    it 'serializes the pipeline status when the branch has a pipeline', :aggregate_failures do
      name = create_related_branch('with-pipeline', with_pipeline: true)

      get api(api_request_path, user)

      row = json_response.find { |r| r['name'] == name }
      expect(row['pipeline_status']).to include('label' => 'passed', 'group' => 'success')
      # Branches without a pipeline still expose the key, as null.
      expect(json_response.find { |r| r['name'] == branch_name }['pipeline_status']).to be_nil
    end

    it 'returns an empty array when the user lacks read_code access' do
      guest = create(:user, guest_of: project)
      stub_feature_flags(work_item_rest_api: [user, guest])

      get api(api_request_path, guest)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/related_branches' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/related_branches" }

    it_behaves_like 'related_branches endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      other_user = create(:user)
      stub_feature_flags(work_item_rest_api: [user, other_user])

      get api(api_request_path, other_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    # The shared N+1 example uses pipeline-less branches; this pins the cost when branches have
    # pipelines, since RelatedBranchesService queries latest_pipeline per branch.
    it 'stays within the known per-branch pipeline query cost',
      :request_store, :use_sql_query_cache, :aggregate_failures do
      2.times { |i| create_related_branch("pipe-base#{i}", with_pipeline: true) }

      # Warm up so first-request lazy writes do not skew the baseline.
      get api(api_request_path, user)

      control = ActiveRecord::QueryRecorder.new { get api(api_request_path, user) }

      added = 2
      added.times { |i| create_related_branch("pipe-more#{i}", with_pipeline: true) }

      queries_per_branch_with_pipeline = 2

      expect { get api(api_request_path, user) }
        .not_to exceed_query_limit(control)
        .with_threshold(queries_per_branch_with_pipeline * added)
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/related_branches' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/related_branches"
    end

    it_behaves_like 'related_branches endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
