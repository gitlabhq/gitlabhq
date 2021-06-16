# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::LabelsPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:filepath) { 'spec/fixtures/bulk_imports/gz/labels.ndjson.gz' }
  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      group: group,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_name: 'My Destination Group',
      destination_namespace: group.full_path
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:tmpdir) { Dir.mktmpdir }

  before do
    FileUtils.copy_file(filepath, File.join(tmpdir, 'labels.ndjson.gz'))
    group.add_owner(user)
  end

  subject { described_class.new(context) }

  describe '#run' do
    it 'imports group labels into destination group and removes tmpdir' do
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
      allow_next_instance_of(BulkImports::FileDownloadService) do |service|
        allow(service).to receive(:execute)
      end

      expect { subject.run }.to change(::GroupLabel, :count).by(1)

      label = group.labels.first

      expect(label.title).to eq('Label 1')
      expect(label.description).to eq('Label 1')
      expect(label.color).to eq('#6699cc')
      expect(File.directory?(tmpdir)).to eq(false)
    end
  end

  describe '#load' do
    context 'when label is not persisted' do
      it 'saves the label' do
        label = build(:group_label, group: group)

        expect(label).to receive(:save!)

        subject.load(context, label)
      end
    end

    context 'when label is persisted' do
      it 'does not save label' do
        label = create(:group_label, group: group)

        expect(label).not_to receive(:save!)

        subject.load(context, label)
      end
    end

    context 'when label is missing' do
      it 'returns' do
        expect(subject.load(context, nil)).to be_nil
      end
    end
  end
end
