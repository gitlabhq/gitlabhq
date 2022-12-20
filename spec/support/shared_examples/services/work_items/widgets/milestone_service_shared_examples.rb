# frozen_string_literal: true

RSpec.shared_examples "setting work item's milestone" do
  context "when 'milestone' param does not exist" do
    let(:params) { {} }

    it "does not set the work item's milestone" do
      expect { execute_callback }.to not_change(work_item, :milestone)
    end
  end

  context "when 'milestone' is not in the work item's project's hierarchy" do
    let(:another_group_milestone) { create(:milestone, group: create(:group)) }
    let(:params) { { milestone_id: another_group_milestone.id } }

    it "does not set the work item's milestone" do
      expect { execute_callback }.to not_change(work_item, :milestone)
    end
  end

  context 'when assigning a group milestone' do
    let(:params) { { milestone_id: group_milestone.id } }

    it "sets the work item's milestone" do
      expect { execute_callback }
        .to change { work_item.milestone }
        .from(nil)
        .to(group_milestone)
    end
  end

  context 'when assigning a project milestone' do
    let(:params) { { milestone_id: project_milestone.id } }

    it "sets the work item's milestone" do
      expect { execute_callback }
        .to change { work_item.milestone }
        .from(nil)
        .to(project_milestone)
    end
  end
end
