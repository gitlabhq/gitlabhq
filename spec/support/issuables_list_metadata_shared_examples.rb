shared_examples 'issuables list meta-data' do |issuable_type, action = nil|
  before do
    @issuable_ids = []

    2.times do
      if issuable_type == :issue
        issuable = create(issuable_type, project: project)
      else
        issuable = create(issuable_type, title: FFaker::Lorem.sentence, source_project: project, source_branch: FFaker::Name.name)
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
      get :index, namespace_id: project.namespace.path, project_id: project.path
    end

    meta_data = assigns(:issuable_meta_data)

    @issuable_ids.each do |id|
      expect(meta_data[id].notes_count).to eq(id)
      expect(meta_data[id].downvotes).to eq(id + 1)
      expect(meta_data[id].upvotes).to eq(id + 2)
    end
  end
end
