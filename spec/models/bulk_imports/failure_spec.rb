# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Failure, type: :model do
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
  end
end
