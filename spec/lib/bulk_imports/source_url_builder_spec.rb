# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::SourceUrlBuilder, feature_category: :importers do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:configuration) { create(:bulk_import_configuration, bulk_import: bulk_import) }

  let(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }
  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let(:entry) { Issue.new(iid: 1, title: 'hello world') }

  describe '#url' do
    subject { described_class.new(context, entry) }

    before do
      allow(subject).to receive(:relation).and_return('issues')
    end

    context 'when relation is allowed' do
      context 'when entity is a group' do
        it 'returns the url specific to groups' do
          expected_url = File.join(
            configuration.url,
            'groups',
            entity.source_full_path,
            '-',
            'issues',
            '1'
          )

          expect(subject.url).to eq(expected_url)
        end
      end

      context 'when entity is a project' do
        let(:entity) { create(:bulk_import_entity, :project_entity, bulk_import: bulk_import) }

        it 'returns the url' do
          expected_url = File.join(
            configuration.url,
            entity.source_full_path,
            '-',
            'issues',
            '1'
          )

          expect(subject.url).to eq(expected_url)
        end
      end
    end

    context 'when entry is not an ApplicationRecord' do
      let(:entry) { 'not an ApplicationRecord' }

      it 'returns nil' do
        expect(subject.url).to be_nil
      end
    end

    context 'when relation is not allowed' do
      it 'returns nil' do
        allow(subject).to receive(:relation).and_return('not_allowed')

        expect(subject.url).to be_nil
      end
    end

    context 'when entry has no iid' do
      let(:entry) { Issue.new }

      it 'returns nil' do
        expect(subject.url).to be_nil
      end
    end
  end
end
