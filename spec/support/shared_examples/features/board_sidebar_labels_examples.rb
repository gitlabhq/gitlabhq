# frozen_string_literal: true

RSpec.shared_context 'labels from nested groups and projects' do
  let_it_be(:group) { create(:group) }
  let_it_be(:group_label) { create(:group_label, group: group, name: 'Group label') }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:project_label) { create(:label, project: project, name: 'Project label') }

  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:subgroup_label) { create(:group_label, group: subgroup, name: 'Subgroup label') }
  let_it_be(:subproject) { create(:project, group: subgroup) }
  let_it_be(:subproject_label) { create(:label, project: subproject, name: 'Subproject label') }

  let_it_be(:subgroup2) { create(:group, parent: group) }
  let_it_be(:subgroup2_label) { create(:group_label, group: subgroup2, name: 'Subgroup2 label') }

  let_it_be(:maintainer) { create(:user) }

  let(:labels_select) { find("[data-testid='sidebar-labels']") }
  let(:labels_dropdown) { labels_select.find('[data-testid="dropdown-content"]') }

  let(:work_item_labels_select) { find_by_testid('work-item-labels') }
  let(:work_item_labels_dropdown) { work_item_labels_select.find('[data-testid="base-dropdown-menu"]') }

  before do
    group.add_maintainer(maintainer)

    sign_in(maintainer)
  end
end

RSpec.shared_examples "an issue from a subgroup's project is selected" do
  context 'when editing labels' do
    before do
      click_card_and_edit_label
    end

    it 'displays the label from the top-level group' do
      expect(labels_dropdown).to have_content(group_label.name)
    end

    it 'displays the label from the subgroup' do
      expect(labels_dropdown).to have_content(subgroup_label.name)
    end

    it 'displays the label from the project' do
      expect(labels_dropdown).to have_content(subproject_label.name)
    end

    it "does not display labels from the subgroup's siblings (project or group)" do
      aggregate_failures do
        expect(labels_dropdown).not_to have_content(project_label.name)
        expect(labels_dropdown).not_to have_content(subgroup2_label.name)
      end
    end
  end
end

RSpec.shared_examples 'an issue from a direct descendant project is selected' do
  context 'when editing labels' do
    before do
      click_card_and_edit_label
    end

    it 'displays the label from the top-level group' do
      expect(labels_dropdown).to have_content(group_label.name)
    end

    it 'displays the label from the project' do
      expect(labels_dropdown).to have_content(project_label.name)
    end

    it "does not display labels from the project's siblings or their descendents" do
      aggregate_failures do
        expect(labels_dropdown).not_to have_content(subgroup_label.name)
        expect(labels_dropdown).not_to have_content(subproject_label.name)
      end
    end
  end
end

RSpec.shared_examples "work item from a direct descendant project is selected" do
  context 'when editing labels' do
    before do
      click_card(card)

      within(work_item_labels_select) do
        click_button 'Edit'

        wait_for_requests
      end
    end

    it 'displays the label from the top-level group' do
      expect(work_item_labels_dropdown).to have_content(group_label.name)
    end

    it 'displays the label from the project' do
      expect(work_item_labels_dropdown).to have_content(project_label.name)
    end

    it "does not display labels from the project's siblings or their descendents" do
      aggregate_failures do
        expect(work_item_labels_dropdown).not_to have_content(subgroup_label.name)
        expect(work_item_labels_dropdown).not_to have_content(subproject_label.name)
      end
    end
  end
end

RSpec.shared_examples "work item from a subgroup's project is selected" do
  context 'when editing labels' do
    before do
      click_card(card)

      within(work_item_labels_select) do
        click_button 'Edit'

        wait_for_requests
      end
    end

    it 'displays the label from the top-level group' do
      expect(work_item_labels_dropdown).to have_content(group_label.name)
    end

    it 'displays the label from the subgroup' do
      expect(work_item_labels_dropdown).to have_content(subgroup_label.name)
    end

    it 'displays the label from the project' do
      expect(work_item_labels_dropdown).to have_content(subproject_label.name)
    end

    it "does not display labels from the subgroup's siblings (project or group)" do
      aggregate_failures do
        expect(work_item_labels_dropdown).not_to have_content(project_label.name)
        expect(work_item_labels_dropdown).not_to have_content(subgroup2_label.name)
      end
    end
  end
end
