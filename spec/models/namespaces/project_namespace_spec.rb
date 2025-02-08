# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProjectNamespace, type: :model, feature_category: :groups_and_projects do
  let_it_be(:organization) { create(:organization) }

  describe 'relationships' do
    it { is_expected.to have_one(:project).inverse_of(:project_namespace) }

    specify do
      project = create(:project)
      namespace = project.project_namespace
      namespace.reload_project

      expect(namespace.project).to eq project
    end
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of :owner }
  end

  context 'when deleting project namespace' do
    # using delete rather than destroy due to `delete` skipping AR hooks/callbacks
    # so it's ensured to work at the DB level. Uses ON DELETE CASCADE on foreign key
    let_it_be(:project) { create(:project) }
    let_it_be(:project_namespace) { project.project_namespace }

    it 'also deletes associated project' do
      project_namespace.delete

      expect { project_namespace.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.create_from_project!' do
    context 'when namespace does not exist' do
      it 'new project_namespace is not saved' do
        expect_any_instance_of(described_class) do |instance|
          expect(instance).not_to receive(:save!)
        end

        project = Project.new(namespace: nil)
        described_class.create_from_project!(project)
      end
    end

    context 'for new record when namespace exists' do
      let(:project) { build(:project, organization: organization) }
      let(:project_namespace) { project.project_namespace }

      it 'syncs the project attributes to project namespace' do
        project_name = 'project 1 name'
        project.name = project_name

        described_class.create_from_project!(project)
        expect(project.project_namespace.name).to eq(project_name)
        expect(project.project_namespace.organization_id).to eq(project.organization_id)
      end

      context 'when project has an unsaved project namespace' do
        it 'saves the same project namespace' do
          described_class.create_from_project!(project)

          expect(project_namespace).to be_persisted
        end
      end
    end
  end

  describe '#sync_attributes_from_project' do
    context 'with existing project' do
      let(:project) { build(:project, organization: organization) }
      let(:project_namespace) { project.project_namespace }
      let(:project_new_namespace) { create(:namespace) }
      let(:project_new_path) { 'project-new-path' }
      let(:project_new_name) { project_new_path.titleize }
      let(:project_new_visibility_level) { Gitlab::VisibilityLevel::INTERNAL }
      let(:project_shared_runners_enabled) { !project.shared_runners_enabled }

      before do
        project.name = project_new_name
        project.path = project_new_path
        project.visibility_level = project_new_visibility_level
        project.namespace = project_new_namespace
        project.shared_runners_enabled = project_shared_runners_enabled
      end

      it 'syncs the relevant keys from the project' do
        project_namespace.sync_attributes_from_project(project)

        expect(project_namespace.name).to eq(project_new_name)
        expect(project_namespace.path).to eq(project_new_path)
        expect(project_namespace.visibility_level).to eq(project_new_visibility_level)
        expect(project_namespace.namespace).to eq(project_new_namespace)
        expect(project_namespace.namespace_id).to eq(project_new_namespace.id)
        expect(project_namespace.shared_runners_enabled).to eq(project_shared_runners_enabled)
        expect(project_namespace.organization_id).to eq(project.organization_id)
      end
    end

    it 'syncs visibility_level if project is new' do
      project = build(:project)
      project_namespace = project.project_namespace
      project_namespace.visibility_level = Gitlab::VisibilityLevel::PUBLIC

      project_namespace.sync_attributes_from_project(project)

      expect(project_namespace.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  describe '#all_projects' do
    let(:project) { create(:project) }
    let(:project_namespace) { project.project_namespace }

    it 'returns single project relation' do
      expect(project_namespace.all_projects).to be_a(ActiveRecord::Relation)
      expect(project_namespace.all_projects).to match_array([project])
    end
  end

  describe 'combine create and update within a single transaction' do
    let(:issue) { build(:issue, spam: true) }

    subject(:combined_calls) do
      issue.project.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
    end

    it { expect { combined_calls }.not_to raise_error }

    context 'when shared_namespace_locks is false' do
      before do
        stub_feature_flags(shared_namespace_locks: false)
      end

      it { expect { combined_calls }.not_to raise_error }
    end
  end
end
