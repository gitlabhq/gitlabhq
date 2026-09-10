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
        expect(placeholder_membership.errors[:base]).to include('Exactly one of group_id, project_id must be present')
      end

      it 'is invalid when both project and group are present' do
        placeholder_membership.group = create(:group)

        expect(placeholder_membership).to be_invalid
        expect(placeholder_membership.errors[:base]).to include('Exactly one of group_id, project_id must be present')
      end
    end
  end

  describe '#retention_expires_at' do
    it 'defaults to one year from now for a new record' do
      freeze_time do
        membership = build(:import_placeholder_membership, retention_expires_at: nil)
        membership.valid?

        expect(membership.retention_expires_at).to be_within(1.second).of(1.year.from_now)
      end
    end

    it 'defaults to one year from now, not one year from created_at, for a pre-existing record with no value set' do
      created_at = 3.years.ago
      membership = travel_to(created_at) { create(:import_placeholder_membership) }
      membership.update_column(:retention_expires_at, nil)

      freeze_time do
        membership.valid?

        expect(membership.retention_expires_at).to be_within(1.second).of(1.year.from_now)
      end
    end

    it 'does not override an explicitly set value' do
      expires_at = 5.days.from_now
      membership = build(:import_placeholder_membership, retention_expires_at: expires_at)

      membership.valid?

      expect(membership.retention_expires_at).to be_within(1.second).of(expires_at)
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
        expect(placeholder_membership.association(:project).loaded?).to be(true)
      end
    end

    describe '.with_groups' do
      it 'eagerly loads the groups and avoids N+1 queries' do
        create(:import_placeholder_membership, :for_group)
        placeholder_membership = described_class.with_groups.first
        recorder = ActiveRecord::QueryRecorder.new { placeholder_membership.group }

        expect(recorder.count).to be_zero
        expect(placeholder_membership.association(:group).loaded?).to be(true)
      end
    end
  end
end
