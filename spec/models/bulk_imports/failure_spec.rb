# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Failure, type: :model, feature_category: :importers do
  let(:failure) { create(:bulk_import_failure) }

  describe 'associations' do
    it { is_expected.to belong_to(:entity).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:entity) }
  end

  describe '#relation' do
    context 'when pipeline class is valid' do
      it 'returns pipeline defined relation' do
        failure.update!(pipeline_class: 'BulkImports::Common::Pipelines::WikiPipeline')

        expect(failure.relation).to eq('wiki')
      end
    end

    context 'when pipeline class is invalid' do
      it 'returns default relation' do
        failure.update!(pipeline_class: 'foobar')

        expect(failure.relation).to eq('foobar')
      end

      context 'when pipeline class is outside of BulkImports namespace' do
        it 'returns default relation' do
          failure.update!(pipeline_class: 'Gitlab::ImportExport::Importer')

          expect(failure.relation).to eq('importer')
        end
      end

      it 'returns demodulized, underscored, chomped string' do
        failure.update!(pipeline_class: 'BulkImports::Pipelines::Test::TestRelationPipeline')

        expect(failure.relation).to eq('test_relation')
      end
    end

    context 'when subrelation is nil' do
      it 'returns relation' do
        failure = described_class.new(pipeline_class: 'BulkImports::Common::Pipelines::WikiPipeline')

        expect(failure.relation).to eq('wiki')
      end
    end

    context 'when subrelation is present' do
      it 'returns relation and subrelation' do
        failure = described_class.new(
          subrelation: 'subrelation',
          pipeline_class: 'BulkImports::Common::Pipelines::WikiPipeline'
        )

        expect(failure.relation).to eq('wiki, subrelation')
      end
    end
  end

  describe '#exception_message=' do
    it 'filters file paths' do
      failure = described_class.new
      failure.exception_message = 'Failed to read /FILE/PATH'
      expect(failure.exception_message).to eq('Failed to read [FILTERED]')
    end

    it 'truncates long string' do
      failure = described_class.new
      failure.exception_message = 'A' * 1000
      expect(failure.exception_message.size).to eq(255)
    end
  end

  describe '#source_title=' do
    it 'truncates title to 255 characters' do
      failure = described_class.new
      failure.source_title = 'A' * 1000
      expect(failure.source_title.size).to eq(255)
    end
  end

  describe '#source_url=' do
    it 'truncates url to 255 characters' do
      failure = described_class.new
      failure.source_url = 'A' * 1000
      expect(failure.source_url.size).to eq(255)
    end
  end

  describe '#subrelation=' do
    it 'truncates subrelation to 255 characters' do
      failure = described_class.new
      failure.subrelation = 'A' * 1000
      expect(failure.subrelation.size).to eq(255)
    end
  end
end
