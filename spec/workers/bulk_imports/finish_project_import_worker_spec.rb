# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FinishProjectImportWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:job_args) { [project.id] }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      it 'calls after_import for the project' do
        expect_next_found_instance_of(Project) do |project|
          expect(project).to receive(:after_import)
        end

        described_class.new.perform(project.id)
      end

      context 'when no project is found' do
        let(:job_args) { nil }

        it 'returns without error' do
          expect { described_class.new.perform(project.id) }.not_to raise_error
        end
      end
    end
  end
end
