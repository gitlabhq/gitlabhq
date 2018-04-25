shared_examples 'cache counters invalidator' do
  it 'invalidates counter cache for assignees' do
    expect_any_instance_of(User).to receive(:invalidate_merge_request_cache_counts)

    described_class.new(project, user, {}).execute(merge_request)
  end
end

shared_examples 'system notes for milestones' do
  def update_issuable(opts)
    issuable = try(:issue) || try(:merge_request)
    described_class.new(project, user, opts).execute(issuable)
  end

  context 'group milestones' do
    let(:group) { create(:group) }
    let(:group_milestone) { create(:milestone, group: group) }

    before do
      project.update(namespace: group)
      create(:group_member, group: group, user: user)
    end

    it 'creates a system note' do
      expect do
        update_issuable(milestone: group_milestone)
      end.to change { Note.system.count }.by(1)
    end
  end

  context 'project milestones' do
    it 'creates a system note' do
      expect do
        update_issuable(milestone: create(:milestone))
      end.to change { Note.system.count }.by(1)
    end
  end
end
