shared_examples 'issuable update service' do
  def update_issuable(opts)
    described_class.new(project, user, opts).execute(open_issuable)
  end

  context 'changing state' do
    before { expect(project).to receive(:execute_hooks).once }

    context 'to reopened' do
      it 'executes hooks only once' do
        described_class.new(project, user, state_event: 'reopen').execute(closed_issuable)
      end
    end

    context 'to closed' do
      it 'executes hooks only once' do
        described_class.new(project, user, state_event: 'close').execute(open_issuable)
      end
    end
  end

  context 'asssignee_id' do
    it 'does not update assignee when assignee_id is invalid' do
      open_issuable.update(assignee_id: user.id)

      update_issuable(assignee_id: -1)

      expect(open_issuable.reload.assignee).to eq(user)
    end

    it 'unassigns assignee when user id is 0' do
      open_issuable.update(assignee_id: user.id)

      update_issuable(assignee_id: 0)

      expect(open_issuable.assignee_id).to be_nil
    end

    it 'saves assignee when user id is valid' do
      update_issuable(assignee_id: user.id)

      expect(open_issuable.assignee_id).to eq(user.id)
    end

    it 'does not update assignee_id when user cannot read issue' do
      non_member        = create(:user)
      original_assignee = open_issuable.assignee

      update_issuable(assignee_id: non_member.id)

      expect(open_issuable.assignee_id).to eq(original_assignee.id)
    end

    context "when issuable feature is private" do
      levels = [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]

      levels.each do |level|
        it "does not update with unauthorized assignee when project is #{Gitlab::VisibilityLevel.level_name(level)}" do
          assignee = create(:user)
          project.update(visibility_level: level)
          feature_visibility_attr = :"#{open_issuable.model_name.plural}_access_level"
          project.project_feature.update_attribute(feature_visibility_attr, ProjectFeature::PRIVATE)

          expect{ update_issuable(assignee_id: assignee) }.not_to change{ open_issuable.assignee }
        end
      end
    end
  end
end
