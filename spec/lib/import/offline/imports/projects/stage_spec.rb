# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Imports::Projects::Stage, feature_category: :importers do
  let(:entity) { build(:bulk_import_entity, :project_entity) }

  subject(:stage) { described_class.new(entity) }

  it 'raises error when initialized without a BulkImport' do
    expect { described_class.new({}) }.to raise_error(
      ArgumentError, 'Expected an argument of type ::BulkImports::Entity'
    )
  end

  describe '#pipelines' do
    it 'lists all the pipelines' do
      pipelines = stage.pipelines

      expect(pipelines).to include(
        hash_including({
          pipeline: BulkImports::Common::Pipelines::EntityFinisher,
          stage: 0
        })
      )
    end

    it_behaves_like 'a BulkImports::Stage'
  end
end
