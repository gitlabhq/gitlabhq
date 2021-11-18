# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification, query_analyzers: false do
  let_it_be(:pipeline, refind: true) { create(:ci_pipeline) }
  let_it_be(:project, refind: true) { create(:project) }

  before do
    allow(Gitlab::Database::QueryAnalyzer.instance).to receive(:all_analyzers).and_return([described_class])
  end

  around do |example|
    Gitlab::Database::QueryAnalyzer.instance.within { example.run }
  end

  shared_examples 'successful examples' do
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

    include_examples 'successful examples'
  end

  context 'when only CI data is modified' do
    def run_queries
      pipeline.touch
      project.reload
    end

    include_examples 'successful examples'
  end

  context 'when other data is modified' do
    def run_queries
      pipeline.reload
      project.touch
    end

    include_examples 'successful examples'
  end

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
          expect { run_queries }.to raise_error /Cross-database data modification/
        end
      end

      context 'when data modification happens in nested transactions' do
        it 'raises error' do
          Project.transaction(requires_new: true) do
            project.touch
            Project.transaction(requires_new: true) do
              expect { pipeline.touch }.to raise_error /Cross-database data modification/
            end
          end
        end
      end
    end

    context 'when executing a SELECT FOR UPDATE query' do
      def run_queries
        project.touch
        pipeline.lock!
      end

      context 'outside transaction' do
        it { expect { run_queries }.not_to raise_error }
      end

      context 'when data modification happens in a transaction' do
        it 'raises error' do
          Project.transaction do
            expect { run_queries }.to raise_error /Cross-database data modification/
          end
        end

        context 'when the modification is inside a factory save! call' do
          let(:runner) { create(:ci_runner, :project, projects: [build(:project)]) }

          it 'does not raise an error' do
            runner
          end
        end
      end
    end

    context 'when CI association is modified through project' do
      def run_queries
        project.variables.build(key: 'a', value: 'v')
        project.save!
      end

      include_examples 'successful examples'
    end

    describe '.allow_cross_database_modification_within_transaction' do
      it 'skips raising error' do
        expect do
          described_class.allow_cross_database_modification_within_transaction(url: 'gitlab-issue') do
            Project.transaction do
              pipeline.touch
              project.touch
            end
          end
        end.not_to raise_error
      end

      it 'skips raising error on factory creation' do
        expect do
          described_class.allow_cross_database_modification_within_transaction(url: 'gitlab-issue') do
            ApplicationRecord.transaction do
              create(:ci_pipeline)
            end
          end
        end.not_to raise_error
      end
    end
  end

  context 'when some table with a defined schema and another table with undefined gitlab_schema is modified' do
    it 'raises an error including including message about undefined schema' do
      expect do
        Project.transaction do
          project.touch
          project.connection.execute('UPDATE foo_bars_undefined_table SET a=1 WHERE id = -1')
        end
      end.to raise_error /Cross-database data modification.*The gitlab_schema was undefined/
    end
  end
end
