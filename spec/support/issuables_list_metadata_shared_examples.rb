shared_examples 'issuables list meta-data' do |issuable_type, action = nil|
  before do
    @issuable_ids = []

    %w[fix improve/awesome].each do |source_branch|
      issuable =
        if issuable_type == :issue
          create(issuable_type, project: project)
        else
          create(issuable_type, source_project: project, source_branch: source_branch)
        end

      @issuable_ids << issuable.id
    end
  end

  it "creates indexed meta-data object for issuable notes and votes count" do
    if action
      get action
    else
      get :index, namespace_id: project.namespace, project_id: project
    end

    meta_data = assigns(:issuable_meta_data)

    aggregate_failures do
      expect(meta_data.keys).to match_array(@issuable_ids)
      expect(meta_data.values).to all(be_kind_of(Issuable::IssuableMeta))
    end
  end

  describe "when given empty collection" do
    let(:project2) { create(:project, :public) }

    it "doesn't execute any queries with false conditions" do
      get_action =
        if action
          proc { get action }
        else
          proc { get :index, namespace_id: project2.namespace, project_id: project2 }
        end

      expect(&get_action).not_to make_queries_matching(/WHERE (?:1=0|0=1)/)
    end
  end
end
