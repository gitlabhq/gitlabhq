# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Placeholders::Membership, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:source_user).class_name('Import::SourceUser') }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }

    it 'is destroyed when source user is destroyed' do
      placeholder_membership = create(:import_placeholder_membership)

      expect { placeholder_membership.source_user.destroy! }.to change { described_class.count }.by(-1)
    end

    it 'is destroyed when namespace is destroyed' do
      placeholder_membership = create(:import_placeholder_membership)

      expect { placeholder_membership.namespace.destroy! }.to change { described_class.count }.by(-1)
    end

    it 'is destroyed when group is destroyed' do
      placeholder_membership = create(:import_placeholder_membership, :for_group)

      expect { placeholder_membership.group.destroy! }.to change { described_class.count }.by(-1)
    end

    it 'is destroyed when project is destroyed' do
      placeholder_membership = create(:import_placeholder_membership)

      expect { placeholder_membership.project.destroy! }.to change { described_class.count }.by(-1)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_presence_of(:source_user_id) }
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_inclusion_of(:access_level).in_array(Gitlab::Access.all_values) }

    describe 'uniqueness scopes' do
      let_it_be(:source_user) { create(:import_source_user) }

      it 'validates uniqueness of project_id scoped to source_user_id' do
        placeholder_membership = build(:import_placeholder_membership, source_user: source_user)
        expect(placeholder_membership).to validate_uniqueness_of(:project_id).scoped_to(:source_user_id).allow_nil
      end

      it 'validates uniqueness of group_id scoped to source_user_id' do
        placeholder_membership = build(:import_placeholder_membership, :for_group, source_user: source_user)
        expect(placeholder_membership).to validate_uniqueness_of(:group_id).scoped_to(:source_user_id).allow_nil
      end
    end

    describe '#validate_project_or_group_present' do
      let_it_be_with_refind(:placeholder_membership) { create(:import_placeholder_membership) }

      it 'is valid when just project is present' do
        expect(placeholder_membership).to be_valid
      end

      it 'is valid when just group is present' do
        placeholder_membership.project = nil
        placeholder_membership.group = create(:group)

        expect(placeholder_membership).to be_valid
      end

      it 'is invalid when both project and group are blank' do
        placeholder_membership.project = nil

        expect(placeholder_membership).to be_invalid
        expect(placeholder_membership.errors[:base]).to include('one of group_id or project_id must be present')
      end

      it 'is invalid when both project and group are present' do
        placeholder_membership.group = create(:group)

        expect(placeholder_membership).to be_invalid
        expect(placeholder_membership.errors[:base]).to include('one of group_id or project_id must be present')
      end
    end
  end

  describe 'Scopes' do
    describe '.by_source_user' do
      it 'returns records by source user' do
        source_user = create(:import_source_user)
        placeholder_membership = create(:import_placeholder_membership, source_user: source_user)
        create(:import_placeholder_membership, source_user: create(:import_source_user))

        expect(described_class.by_source_user(source_user)).to eq([placeholder_membership])
      end
    end

    describe '.by_project' do
      it 'returns records by project' do
        project = create(:project)
        other_project = create(:project)
        group = create(:group)

        placeholder_membership = create(:import_placeholder_membership, project: project)
        create(:import_placeholder_membership, project: other_project)
        create(:import_placeholder_membership, :for_group, group: group)

        expect(described_class.by_project(project)).to eq([placeholder_membership])
      end
    end

    describe '.by_group' do
      it 'returns records by group' do
        group = create(:group)
        other_group = create(:group)
        project = create(:project, group: group)

        placeholder_membership = create(:import_placeholder_membership, :for_group, group: group)
        create(:import_placeholder_membership, :for_group, group: other_group)
        create(:import_placeholder_membership, project: project)

        expect(described_class.by_group(group)).to eq([placeholder_membership])
      end
    end

    describe '.with_projects' do
      it 'eagerly loads the projects and avoids N+1 queries' do
        create(:import_placeholder_membership)
        placeholder_membership = described_class.with_projects.first
        recorder = ActiveRecord::QueryRecorder.new { placeholder_membership.project }

        expect(recorder.count).to be_zero
        expect(placeholder_membership.association(:project).loaded?).to eq(true)
      end
    end

    describe '.with_groups' do
      it 'eagerly loads the groups and avoids N+1 queries' do
        create(:import_placeholder_membership, :for_group)
        placeholder_membership = described_class.with_groups.first
        recorder = ActiveRecord::QueryRecorder.new { placeholder_membership.group }

        expect(recorder.count).to be_zero
        expect(placeholder_membership.association(:group).loaded?).to eq(true)
      end
    end
  end
end
