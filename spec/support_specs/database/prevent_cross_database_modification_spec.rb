# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database::PreventCrossDatabaseModification' do
  let_it_be(:pipeline, refind: true) { create(:ci_pipeline) }
  let_it_be(:project, refind: true) { create(:project) }

  shared_examples 'succeessful examples' do
    context 'outside transaction' do
      it { expect { run_queries }.not_to raise_error }
    end

    context 'within transaction' do
      it do
        Project.transaction do
          expect { run_queries }.not_to raise_error
        end
      end
    end

    context 'within nested transaction' do
      it do
        Project.transaction(requires_new: true) do
          Project.transaction(requires_new: true) do
            expect { run_queries }.not_to raise_error
          end
        end
      end
    end
  end

  context 'when CI and other tables are read in a transaction' do
    def run_queries
      pipeline.reload
      project.reload
    end

    include_examples 'succeessful examples'
  end

  context 'when only CI data is modified' do
    def run_queries
      pipeline.touch
      project.reload
    end

    include_examples 'succeessful examples'
  end

  context 'when other data is modified' do
    def run_queries
      pipeline.reload
      project.touch
    end

    include_examples 'succeessful examples'
  end

  describe 'with_cross_database_modification_prevented block' do
    it 'raises error when CI and other data is modified' do
      expect do
        with_cross_database_modification_prevented do
          Project.transaction do
            project.touch
            pipeline.touch
          end
        end
      end.to raise_error /Cross-database data modification queries/
    end
  end

  context 'when running tests with prevent_cross_database_modification', :prevent_cross_database_modification do
    context 'when both CI and other data is modified' do
      def run_queries
        project.touch
        pipeline.touch
      end

      context 'outside transaction' do
        it { expect { run_queries }.not_to raise_error }
      end

      context 'when data modification happens in a transaction' do
        it 'raises error' do
          Project.transaction do
            expect { run_queries }.to raise_error /Cross-database data modification queries/
          end
        end

        context 'when data modification happens in nested transactions' do
          it 'raises error' do
            Project.transaction(requires_new: true) do
              project.touch
              Project.transaction(requires_new: true) do
                expect { pipeline.touch }.to raise_error /Cross-database data modification queries/
              end
            end
          end
        end
      end
    end

    context 'when CI association is modified through project' do
      def run_queries
        project.variables.build(key: 'a', value: 'v')
        project.save!
      end

      include_examples 'succeessful examples'
    end

    describe '#allow_cross_database_modification_within_transaction' do
      it 'skips raising error' do
        expect do
          Gitlab::Database.allow_cross_database_modification_within_transaction(url: 'gitlab-issue') do
            Project.transaction do
              pipeline.touch
              project.touch
            end
          end
        end.not_to raise_error
      end

      it 'raises error when complex factories are built referencing both databases' do
        expect do
          ApplicationRecord.transaction do
            create(:ci_pipeline)
          end
        end.to raise_error /Cross-database data modification queries/
      end

      it 'skips raising error on factory creation' do
        expect do
          Gitlab::Database.allow_cross_database_modification_within_transaction(url: 'gitlab-issue') do
            ApplicationRecord.transaction do
              create(:ci_pipeline)
            end
          end
        end.not_to raise_error
      end
    end
  end
end
