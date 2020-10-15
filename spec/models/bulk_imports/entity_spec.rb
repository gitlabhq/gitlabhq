# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Entity, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:bulk_import).required }
    it { is_expected.to belong_to(:parent) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_presence_of(:source_full_path) }
    it { is_expected.to validate_presence_of(:destination_name) }
    it { is_expected.to validate_presence_of(:destination_namespace) }

    it { is_expected.to define_enum_for(:source_type).with_values(%i[group_entity project_entity]) }

    context 'when associated with a group and project' do
      it 'is invalid' do
        entity = build(:bulk_import_entity, group: build(:group), project: build(:project))

        expect(entity).not_to be_valid
        expect(entity.errors).to include(:project, :group)
      end
    end

    context 'when not associated with a group or project' do
      it 'is valid' do
        entity = build(:bulk_import_entity, group: nil, project: nil)

        expect(entity).to be_valid
      end
    end

    context 'when associated with a group and no project' do
      it 'is valid as a group_entity' do
        entity = build(:bulk_import_entity, :group_entity, group: build(:group), project: nil)

        expect(entity).to be_valid
      end

      it 'is invalid as a project_entity' do
        entity = build(:bulk_import_entity, :project_entity, group: build(:group), project: nil)

        expect(entity).not_to be_valid
        expect(entity.errors).to include(:group)
      end
    end

    context 'when associated with a project and no group' do
      it 'is valid' do
        entity = build(:bulk_import_entity, :project_entity, group: nil, project: build(:project))

        expect(entity).to be_valid
      end

      it 'is invalid as a project_entity' do
        entity = build(:bulk_import_entity, :group_entity, group: nil, project: build(:project))

        expect(entity).not_to be_valid
        expect(entity.errors).to include(:project)
      end
    end

    context 'when the parent is a group import' do
      it 'is valid' do
        entity = build(:bulk_import_entity, parent: build(:bulk_import_entity, :group_entity))

        expect(entity).to be_valid
      end
    end

    context 'when the parent is a project import' do
      it 'is invalid' do
        entity = build(:bulk_import_entity, parent: build(:bulk_import_entity, :project_entity))

        expect(entity).not_to be_valid
        expect(entity.errors).to include(:parent)
      end
    end
  end
end
