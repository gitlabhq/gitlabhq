# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Export, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:upload) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:relation) }
    it { is_expected.to validate_presence_of(:status) }

    context 'when not associated with a group or project' do
      it 'is invalid' do
        export = build(:bulk_import_export, group: nil, project: nil)

        expect(export).not_to be_valid
      end
    end

    context 'when associated with a group' do
      it 'is valid' do
        export = build(:bulk_import_export, group: build(:group), project: nil)

        expect(export).to be_valid
      end
    end

    context 'when associated with a project' do
      it 'is valid' do
        export = build(:bulk_import_export, group: nil, project: build(:project))

        expect(export).to be_valid
      end
    end

    context 'when relation is invalid' do
      it 'is invalid' do
        export = build(:bulk_import_export, relation: 'unsupported')

        expect(export).not_to be_valid
        expect(export.errors).to include(:relation)
      end
    end
  end

  describe '#portable' do
    context 'when associated with project' do
      it 'returns project' do
        export = create(:bulk_import_export, project: create(:project), group: nil)

        expect(export.portable).to be_instance_of(Project)
      end
    end

    context 'when associated with group' do
      it 'returns group' do
        export = create(:bulk_import_export)

        expect(export.portable).to be_instance_of(Group)
      end
    end
  end

  describe '#config' do
    context 'when associated with project' do
      it 'returns project config' do
        export = create(:bulk_import_export, project: create(:project), group: nil)

        expect(export.config).to be_instance_of(BulkImports::FileTransfer::ProjectConfig)
      end
    end

    context 'when associated with group' do
      it 'returns group config' do
        export = create(:bulk_import_export)

        expect(export.config).to be_instance_of(BulkImports::FileTransfer::GroupConfig)
      end
    end
  end
end
