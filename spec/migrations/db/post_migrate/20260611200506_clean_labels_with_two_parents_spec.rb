# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanLabelsWithTwoParents, migration: :gitlab_main_org, feature_category: :team_planning do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:labels) { table(:labels) }

  let!(:organization) { organizations.create!(name: 'Organization 1', path: 'organization-1') }

  let!(:group) do
    namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let!(:project_namespace) do
    namespaces.create!(name: 'project', path: 'project', type: 'Project', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  # Each context overrides `existing_labels` to declare the rows to seed.
  let(:existing_labels) { [] }

  # A NOT VALID check constraint already enforces exactly one of
  # group_id/organization_id/project_id on new rows. We drop it only while
  # seeding the invalid rows declared in `existing_labels`, then re-add it
  # (still NOT VALID) so the migration runs against the production-like schema.
  before do
    connection = labels.connection
    connection.remove_check_constraint(:labels, name: 'check_2d9a8c1bca')

    existing_labels

    connection.add_check_constraint(
      :labels,
      'num_nonnulls(group_id, organization_id, project_id) = 1',
      name: 'check_2d9a8c1bca',
      validate: false
    )
  end

  def create_label(title:, type:, group_id: nil, project_id: nil)
    labels.create!(title: title, color: '#990000', type: type, group_id: group_id, project_id: project_id)
  end

  context 'when a ProjectLabel has both group_id and project_id' do
    context 'without a title collision' do
      let(:label) do
        create_label(title: 'unique', type: 'ProjectLabel', group_id: group.id, project_id: project.id)
      end

      let(:existing_labels) { [label] }

      it 'clears group_id and keeps the title' do
        migrate!

        label.reload
        expect(label.group_id).to be_nil
        expect(label.project_id).to eq(project.id)
        expect(label.title).to eq('unique')
      end
    end

    context 'with a colliding project label in the same project' do
      let(:clean_label) do
        create_label(title: 'duped', type: 'ProjectLabel', project_id: project.id)
      end

      let(:broken_label) do
        create_label(title: 'duped', type: 'ProjectLabel', group_id: group.id, project_id: project.id)
      end

      let(:existing_labels) { [clean_label, broken_label] }

      it 'clears group_id and renames the broken label' do
        migrate!

        broken_label.reload
        expect(broken_label.group_id).to be_nil
        expect(broken_label.project_id).to eq(project.id)
        expect(broken_label.title).to eq("duped [dup #{broken_label.id}]")
      end

      it 'does not modify the clean label' do
        expect { migrate! }.not_to change { clean_label.reload.attributes }
      end
    end

    context 'with a clean label and two broken labels sharing the title' do
      let(:clean_label) do
        create_label(title: 'duped', type: 'ProjectLabel', project_id: project.id)
      end

      let(:broken_label_one) do
        create_label(title: 'duped', type: 'ProjectLabel', group_id: group.id, project_id: project.id)
      end

      let(:broken_label_two) do
        create_label(title: 'duped', type: 'ProjectLabel', group_id: group.id, project_id: project.id)
      end

      let(:existing_labels) { [clean_label, broken_label_one, broken_label_two] }

      it 'renames each broken label with its own id' do
        migrate!

        expect(broken_label_one.reload.title).to eq("duped [dup #{broken_label_one.id}]")
        expect(broken_label_two.reload.title).to eq("duped [dup #{broken_label_two.id}]")
      end

      it 'does not modify the clean label' do
        expect { migrate! }.not_to change { clean_label.reload.attributes }
      end
    end

    context 'with two broken labels sharing the title and no clean label' do
      let(:broken_label_one) do
        create_label(title: 'duped', type: 'ProjectLabel', group_id: group.id, project_id: project.id)
      end

      let(:broken_label_two) do
        create_label(title: 'duped', type: 'ProjectLabel', group_id: group.id, project_id: project.id)
      end

      let(:existing_labels) { [broken_label_one, broken_label_two] }

      it 'clears group_id and renames each label with its own id' do
        migrate!

        expect(broken_label_one.reload).to have_attributes(
          group_id: nil, project_id: project.id, title: "duped [dup #{broken_label_one.id}]"
        )
        expect(broken_label_two.reload).to have_attributes(
          group_id: nil, project_id: project.id, title: "duped [dup #{broken_label_two.id}]"
        )
      end
    end
  end

  context 'when a GroupLabel has both group_id and project_id' do
    context 'without a title collision' do
      let(:label) do
        create_label(title: 'unique', type: 'GroupLabel', group_id: group.id, project_id: project.id)
      end

      let(:existing_labels) { [label] }

      it 'clears project_id and keeps the title' do
        migrate!

        label.reload
        expect(label.project_id).to be_nil
        expect(label.group_id).to eq(group.id)
        expect(label.title).to eq('unique')
      end
    end

    context 'with a colliding group label in the same group' do
      let(:clean_label) do
        create_label(title: 'duped', type: 'GroupLabel', group_id: group.id)
      end

      let(:broken_label) do
        create_label(title: 'duped', type: 'GroupLabel', group_id: group.id, project_id: project.id)
      end

      let(:existing_labels) { [clean_label, broken_label] }

      it 'clears project_id and renames the broken label' do
        migrate!

        broken_label.reload
        expect(broken_label.project_id).to be_nil
        expect(broken_label.group_id).to eq(group.id)
        expect(broken_label.title).to eq("duped [dup #{broken_label.id}]")
      end

      it 'does not modify the clean label' do
        expect { migrate! }.not_to change { clean_label.reload.attributes }
      end
    end

    context 'with two broken labels sharing the title and no clean label' do
      let(:broken_label_one) do
        create_label(title: 'duped', type: 'GroupLabel', group_id: group.id, project_id: project.id)
      end

      let(:broken_label_two) do
        create_label(title: 'duped', type: 'GroupLabel', group_id: group.id, project_id: project.id)
      end

      let(:existing_labels) { [broken_label_one, broken_label_two] }

      it 'clears project_id and renames each label with its own id' do
        migrate!

        expect(broken_label_one.reload).to have_attributes(
          project_id: nil, group_id: group.id, title: "duped [dup #{broken_label_one.id}]"
        )
        expect(broken_label_two.reload).to have_attributes(
          project_id: nil, group_id: group.id, title: "duped [dup #{broken_label_two.id}]"
        )
      end
    end
  end

  context 'when a label has only a group_id' do
    let(:label) do
      create_label(title: 'group-only', type: 'GroupLabel', group_id: group.id)
    end

    let(:existing_labels) { [label] }

    it 'does not modify the label' do
      expect { migrate! }.not_to change { label.reload.attributes }
    end
  end

  context 'when a label has only a project_id' do
    let(:label) do
      create_label(title: 'project-only', type: 'ProjectLabel', project_id: project.id)
    end

    let(:existing_labels) { [label] }

    it 'does not modify the label' do
      expect { migrate! }.not_to change { label.reload.attributes }
    end
  end

  context 'when there are more broken labels than the batch size' do
    let(:broken_labels) do
      Array.new(3) do |i|
        create_label(title: "label-#{i}", type: 'ProjectLabel', group_id: group.id, project_id: project.id)
      end
    end

    let(:existing_labels) { broken_labels }

    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'runs one UPDATE query per batch' do
      expect { migrate! }.to make_queries_matching(/UPDATE labels/, broken_labels.size)
    end

    it 'processes every broken label across batches' do
      migrate!

      broken_labels.each do |label|
        label.reload
        expect(label.group_id).to be_nil
        expect(label.project_id).to eq(project.id)
      end
    end
  end
end
