shared_examples 'issuables list meta-data' do |issuable_type, action = nil|
  before do
    @issuable_ids = []

    2.times do |n|
      issuable =
        if issuable_type == :issue
          create(issuable_type, project: project)
        else
          create(issuable_type, source_project: project, source_branch: "#{n}-feature")
        end

      @issuable_ids << issuable.id

      issuable.id.times       { create(:note, noteable: issuable, project: issuable.project) }
      (issuable.id + 1).times { create(:award_emoji, :downvote, awardable: issuable) }
      (issuable.id + 2).times { create(:award_emoji, :upvote, awardable: issuable) }
    end
  end

  it "creates indexed meta-data object for issuable notes and votes count" do
    if action
      get action
    else
      get :index, namespace_id: project.namespace, project_id: project
    end

    meta_data = assigns(:issuable_meta_data)

    @issuable_ids.each do |id|
      expect(meta_data[id].notes_count).to eq(id)
      expect(meta_data[id].downvotes).to eq(id + 1)
      expect(meta_data[id].upvotes).to eq(id + 2)
    end
  end

  describe "when given empty collection" do
    let(:project2) { create(:empty_project, :public) }

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
