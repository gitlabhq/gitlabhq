shared_examples 'issuable create service' do
  context 'asssignee_id' do
    let(:assignee) { create(:user) }

    before { project.team << [user, :master] }

    it 'removes assignee_id when user id is invalid' do
      opts = { title: 'Title', description: 'Description', assignee_id: -1 }

      issuable = described_class.new(project, user, opts).execute

      expect(issuable.assignee_id).to be_nil
    end

    it 'removes assignee_id when user id is 0' do
      opts = { title: 'Title', description: 'Description',  assignee_id: 0 }

      issuable = described_class.new(project, user, opts).execute

      expect(issuable.assignee_id).to be_nil
    end

    it 'saves assignee when user id is valid' do
      project.team << [assignee, :master]
      opts = { title: 'Title', description: 'Description', assignee_id: assignee.id }

      issuable = described_class.new(project, user, opts).execute

      expect(issuable.assignee_id).to eq(assignee.id)
    end

    context "when issuable feature is private" do
      before do
        project.project_feature.update(issues_access_level: ProjectFeature::PRIVATE,
                                       merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      levels = [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]

      levels.each do |level|
        it "removes not authorized assignee when project is #{Gitlab::VisibilityLevel.level_name(level)}" do
          project.update(visibility_level: level)
          opts = { title: 'Title', description: 'Description', assignee_id: assignee.id }

          issuable = described_class.new(project, user, opts).execute

          expect(issuable.assignee_id).to be_nil
        end
      end
    end
  end
end
