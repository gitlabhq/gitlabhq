shared_examples 'issuables list meta-data' do |issuable_type, action = nil|
  include ProjectForksHelper

  def get_action(action, project)
    if action
      get action, author_id: project.creator.id
    else
      get :index, namespace_id: project.namespace, project_id: project
    end
  end

  def create_issuable(issuable_type, project, source_branch:)
    if issuable_type == :issue
      create(issuable_type, project: project, author: project.creator)
    else
      create(issuable_type, source_project: project, source_branch: source_branch, author: project.creator)
    end
  end

  before do
    @issuable_ids = %w[fix improve/awesome].map do |source_branch|
      create_issuable(issuable_type, project, source_branch: source_branch).id
    end
  end

  it "creates indexed meta-data object for issuable notes and votes count" do
    get_action(action, project)

    meta_data = assigns(:issuable_meta_data)

    aggregate_failures do
      expect(meta_data.keys).to match_array(@issuable_ids)
      expect(meta_data.values).to all(be_kind_of(Issuable::IssuableMeta))
    end
  end

  it "avoids N+1 queries" do
    control = ActiveRecord::QueryRecorder.new { get_action(action, project) }
    issuable = create_issuable(issuable_type, project, source_branch: 'csv')

    if issuable_type == :merge_request
      issuable.update!(source_project: fork_project(project))
    end

    expect { get_action(action, project) }.not_to exceed_query_limit(control.count)
  end

  describe "when given empty collection" do
    let(:project2) { create(:project, :public) }

    it "doesn't execute any queries with false conditions" do
      get_empty =
        if action
          proc { get action, author_id: project.creator.id }
        else
          proc { get :index, namespace_id: project2.namespace, project_id: project2 }
        end

      expect(&get_empty).not_to make_queries_matching(/WHERE (?:1=0|0=1)/)
    end
  end
end
