# frozen_string_literal: true

require 'spec_helper'
require_migration!('remove_duplicate_labels_from_group')

RSpec.describe RemoveDuplicateLabelsFromGroup do
  let(:labels_table) { table(:labels) }
  let(:labels) { labels_table.all }
  let(:projects_table) { table(:projects) }
  let(:projects) { projects_table.all }
  let(:namespaces_table) { table(:namespaces) }
  let(:namespaces) { namespaces_table.all }
  let(:backup_labels_table) { table(:backup_labels) }
  let(:backup_labels) { backup_labels_table.all }
  # for those cases where we can't use the activerecord class because the `type` column
  # makes it think it has polymorphism and should be/have a Label subclass
  let(:sql_backup_labels) { ApplicationRecord.connection.execute('SELECT * from backup_labels') }

  # all the possible tables with records that may have a relationship with a label
  let(:analytics_cycle_analytics_group_stages_table) { table(:analytics_cycle_analytics_group_stages) }
  let(:analytics_cycle_analytics_project_stages_table) { table(:analytics_cycle_analytics_project_stages) }
  let(:board_labels_table) { table(:board_labels) }
  let(:label_links_table) { table(:label_links) }
  let(:label_priorities_table) { table(:label_priorities) }
  let(:lists_table) { table(:lists) }
  let(:resource_label_events_table) { table(:resource_label_events) }

  let!(:group_one) { namespaces_table.create!(id: 1, type: 'Group', name: 'group', path: 'group') }
  let!(:project_one) do
    projects_table.create!(id: 1, name: 'project', path: 'project',
                           visibility_level: 0, namespace_id: group_one.id)
  end

  let(:label_title) { 'bug' }
  let(:label_color) { 'red' }
  let(:label_description) { 'nice label' }
  let(:project_id) { project_one.id }
  let(:group_id) { group_one.id }
  let(:other_title) { 'feature' }

  let(:group_label_attributes) do
    {
        title: label_title, color: label_color, group_id: group_id, type: 'GroupLabel', template: false, description: label_description
    }
  end

  let(:migration) { described_class.new }

  describe 'removing full duplicates' do
    context 'when there are no duplicate labels' do
      let!(:first_label) { labels_table.create!(group_label_attributes.merge(id: 1, title: "a different label")) }
      let!(:second_label) { labels_table.create!(group_label_attributes.merge(id: 2, title: "a totally different label")) }

      it 'does not remove anything' do
        expect { migration.up }.not_to change { backup_labels_table.count }
      end

      it 'restores removed records when rolling back - no change' do
        migration.up

        expect { migration.down }.not_to change { labels_table.count }
      end
    end

    context 'with duplicates with no relationships' do
      let!(:first_label) { labels_table.create!(group_label_attributes.merge(id: 1)) }
      let!(:second_label) { labels_table.create!(group_label_attributes.merge(id: 2)) }
      let!(:third_label) { labels_table.create!(group_label_attributes.merge(id: 3, title: other_title)) }
      let!(:fourth_label) { labels_table.create!(group_label_attributes.merge(id: 4, title: other_title)) }

      it 'creates a backup record for each removed record' do
        expect { migration.up }.to change { backup_labels_table.count }.from(0).to(2)
      end

      it 'creates the correct backup records with `create` restore_action' do
        migration.up

        expect(sql_backup_labels.find { |bl| bl["id"] == 2 }).to include(second_label.attributes.merge("restore_action" => described_class::CREATE, "new_title" => nil, "created_at" => anything, "updated_at" => anything))
        expect(sql_backup_labels.find { |bl| bl["id"] == 4 }).to include(fourth_label.attributes.merge("restore_action" => described_class::CREATE, "new_title" => nil, "created_at" => anything, "updated_at" => anything))
      end

      it 'deletes all but one' do
        migration.up

        expect { second_label.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { fourth_label.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'restores removed records on rollback' do
        second_label_attributes = modified_attributes(second_label)
        fourth_label_attributes = modified_attributes(fourth_label)

        migration.up

        migration.down

        expect(second_label.attributes).to include(second_label_attributes)
        expect(fourth_label.attributes).to include(fourth_label_attributes)
      end
    end

    context 'two duplicate records, one of which has a relationship' do
      let!(:first_label) { labels_table.create!(group_label_attributes.merge(id: 1)) }
      let!(:second_label) { labels_table.create!(group_label_attributes.merge(id: 2)) }
      let!(:label_priority) { label_priorities_table.create!(label_id: second_label.id, project_id: project_id, priority: 1) }

      it 'does not remove anything' do
        expect { migration.up }.not_to change { labels_table.count }
      end

      it 'does not create a backup record with `create` restore_action' do
        expect { migration.up }.not_to change { backup_labels_table.where(restore_action: described_class::CREATE).count }
      end

      it 'restores removed records when rolling back - no change' do
        migration.up

        expect { migration.down }.not_to change { labels_table.count }
      end
    end

    context 'multiple duplicates, a subset of which have relationships' do
      let!(:first_label) { labels_table.create!(group_label_attributes.merge(id: 1)) }
      let!(:second_label) { labels_table.create!(group_label_attributes.merge(id: 2)) }
      let!(:label_priority_for_second_label) { label_priorities_table.create!(label_id: second_label.id, project_id: project_id, priority: 1) }
      let!(:third_label) { labels_table.create!(group_label_attributes.merge(id: 3)) }
      let!(:fourth_label) { labels_table.create!(group_label_attributes.merge(id: 4)) }
      let!(:label_priority_for_fourth_label) { label_priorities_table.create!(label_id: fourth_label.id, project_id: project_id, priority: 2) }

      it 'creates a backup record with `create` restore_action for each removed record' do
        expect { migration.up }.to change { backup_labels_table.where(restore_action: described_class::CREATE).count }.from(0).to(1)
      end

      it 'creates the correct backup records' do
        migration.up

        expect(sql_backup_labels.find { |bl| bl["id"] == 3 }).to include(third_label.attributes.merge("restore_action" => described_class::CREATE, "new_title" => nil, "created_at" => anything, "updated_at" => anything))
      end

      it 'deletes the duplicate record' do
        migration.up

        expect { first_label.reload }.not_to raise_error
        expect { second_label.reload }.not_to raise_error
        expect { third_label.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'restores removed records on rollback' do
        third_label_attributes = modified_attributes(third_label)

        migration.up
        migration.down

        expect(third_label.attributes).to include(third_label_attributes)
      end
    end
  end

  describe 'renaming partial duplicates' do
    # partial duplicates - only group_id and title match. Distinct colour prevents deletion.
    context 'when there are no duplicate labels' do
      let!(:first_label) { labels_table.create!(group_label_attributes.merge(id: 1, title: "a unique label", color: 'green')) }
      let!(:second_label) { labels_table.create!(group_label_attributes.merge(id: 2, title: "a totally different, unique, label", color: 'blue')) }

      it 'does not rename anything' do
        expect { migration.up }.not_to change { backup_labels_table.count }
      end
    end

    context 'with duplicates with no relationships' do
      let!(:first_label) { labels_table.create!(group_label_attributes.merge(id: 1, color: 'green')) }
      let!(:second_label) { labels_table.create!(group_label_attributes.merge(id: 2, color: 'blue')) }
      let!(:third_label) { labels_table.create!(group_label_attributes.merge(id: 3, title: other_title, color: 'purple')) }
      let!(:fourth_label) { labels_table.create!(group_label_attributes.merge(id: 4, title: other_title, color: 'yellow')) }

      it 'creates a backup record for each renamed record' do
        expect { migration.up }.to change { backup_labels_table.count }.from(0).to(2)
      end

      it 'creates the correct backup records with `rename` restore_action' do
        migration.up

        expect(sql_backup_labels.find { |bl| bl["id"] == 2 }).to include(second_label.attributes.merge("restore_action" => described_class::RENAME, "created_at" => anything, "updated_at" => anything))
        expect(sql_backup_labels.find { |bl| bl["id"] == 4 }).to include(fourth_label.attributes.merge("restore_action" => described_class::RENAME, "created_at" => anything, "updated_at" => anything))
      end

      it 'modifies the titles of the partial duplicates' do
        migration.up

        expect(second_label.reload.title).to match(/#{label_title}_duplicate#{second_label.id}$/)
        expect(fourth_label.reload.title).to match(/#{other_title}_duplicate#{fourth_label.id}$/)
      end

      it 'restores renamed records on rollback' do
        second_label_attributes = modified_attributes(second_label)
        fourth_label_attributes = modified_attributes(fourth_label)

        migration.up

        migration.down

        expect(second_label.reload.attributes).to include(second_label_attributes)
        expect(fourth_label.reload.attributes).to include(fourth_label_attributes)
      end

      context 'when the labels have a long title that might overflow' do
        let(:long_title) { "a" * 255 }

        before do
          first_label.update_attribute(:title, long_title)
          second_label.update_attribute(:title, long_title)
        end

        it 'keeps the length within the limit' do
          migration.up

          expect(second_label.reload.title).to eq("#{"a" * 244}_duplicate#{second_label.id}")
          expect(second_label.title.length).to eq(255)
        end
      end
    end
  end

  def modified_attributes(label)
    label.attributes.except('created_at', 'updated_at')
  end
end
