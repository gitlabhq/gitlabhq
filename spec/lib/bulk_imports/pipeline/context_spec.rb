# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Pipeline::Context do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:project_entity) { create(:bulk_import_entity, :project_entity, project: project) }
  let_it_be(:project_tracker) { create(:bulk_import_tracker, entity: project_entity) }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      source_full_path: 'source/full/path',
      destination_name: 'My Destination Group',
      destination_namespace: group.full_path,
      group: group,
      bulk_import: bulk_import
    )
  end

  let_it_be(:tracker) do
    create(
      :bulk_import_tracker,
      entity: entity,
      pipeline_name: described_class.name
    )
  end

  subject { described_class.new(tracker, extra: :data) }

  describe '#entity' do
    it { expect(subject.entity).to eq(entity) }
  end

  describe '#group' do
    it { expect(subject.group).to eq(group) }
  end

  describe '#bulk_import' do
    it { expect(subject.bulk_import).to eq(bulk_import) }
  end

  describe '#current_user' do
    it { expect(subject.current_user).to eq(user) }
  end

  describe '#configuration' do
    it { expect(subject.configuration).to eq(bulk_import.configuration) }
  end

  describe '#extra' do
    it { expect(subject.extra).to eq(extra: :data) }
  end

  describe '#portable' do
    it { expect(subject.portable).to eq(group) }

    context 'when portable is project' do
      subject { described_class.new(project_tracker) }

      it { expect(subject.portable).to eq(project) }
    end
  end

  describe '#import_export_config' do
    it { expect(subject.import_export_config).to be_instance_of(BulkImports::FileTransfer::GroupConfig) }

    context 'when portable is project' do
      subject { described_class.new(project_tracker) }

      it { expect(subject.import_export_config).to be_instance_of(BulkImports::FileTransfer::ProjectConfig) }
    end
  end
end
