# frozen_string_literal: true

RSpec.shared_examples 'issuables list meta-data' do |issuable_type, action = nil, format: :html|
  include ProjectForksHelper

  def get_action(action, project, extra_params = {})
    if action
      get action, params: { author_id: project.creator.id }.merge(extra_params), format: format
    else
      get :index, params: { namespace_id: project.namespace, project_id: project }.merge(extra_params), format: format
    end
  end

  def create_issuable(issuable_type, project, source_branch:)
    if issuable_type == :issue
      create(issuable_type, project: project, author: project.creator)
    else
      create(issuable_type, source_project: project, source_branch: source_branch, author: project.creator)
    end
  end

  let(:format) { format }

  let!(:issuables) do
    %w[fix improve/awesome].map do |source_branch|
      create_issuable(issuable_type, project, source_branch: source_branch)
    end
  end

  let(:issuable_ids) { issuables.map(&:id) }

  it "creates indexed meta-data object for issuable notes and votes count" do
    get_action(action, project)

    meta_data = assigns(:issuable_meta_data)

    aggregate_failures do
      expect(meta_data.keys).to match_array(issuables.map(&:id))
      expect(meta_data.values).to all(be_kind_of(Gitlab::IssuableMetadata::IssuableMeta))
    end
  end

  context 'searching' do
    let(:result_issuable) { issuables.first }
    let(:search) { result_issuable.title }

    before do
      stub_application_setting(search_rate_limit: 0, search_rate_limit_unauthenticated: 0)
    end

    # .simple_sorts is the same across all Sortable classes
    sorts = ::Issue.simple_sorts.keys + %w[popularity priority label_priority]
    sorts.each do |sort|
      it "works when sorting by #{sort}" do
        get_action(action, project, search: search, sort: sort)

        expect(assigns(:issuable_meta_data).keys).to include(result_issuable.id)
      end
    end
  end

  it "avoids N+1 queries" do
    control = ActiveRecord::QueryRecorder.new { get_action(action, project) }
    issuable = create_issuable(issuable_type, project, source_branch: 'csv')

    if issuable_type == :merge_request
      issuable.update!(source_project: fork_project(project))
    end

    expect { get_action(action, project) }.not_to exceed_query_limit(control)
  end

  describe "when given empty collection" do
    let(:project2) { create(:project, :public) }

    it "doesn't execute any queries with false conditions" do
      get_empty =
        if action
          proc { get action, params: { author_id: project.creator.id } }
        else
          proc { get :index, params: { namespace_id: project2.namespace, project_id: project2 } }
        end

      expect(&get_empty).not_to make_queries_matching(/WHERE (?:1=0|0=1)/)
    end
  end
end
