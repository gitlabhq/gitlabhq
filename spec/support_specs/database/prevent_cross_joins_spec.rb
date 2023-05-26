# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::PreventCrossJoins, :suppress_gitlab_schemas_validate_connection do
  context 'when running in a default scope' do
    context 'when only non-CI tables are used' do
      it 'does not raise exception' do
        expect { main_only_query }.not_to raise_error
      end
    end

    context 'when only CI tables are used' do
      it 'does not raise exception' do
        expect { ci_only_query }.not_to raise_error
      end
    end

    context 'when CI and non-CI tables are used' do
      it 'raises exception' do
        expect { main_and_ci_query }.to raise_error(
          described_class::CrossJoinAcrossUnsupportedTablesError)
      end

      context 'when annotation is used' do
        it 'does not raise exception' do
          expect { main_and_ci_allowed_via_annotate }.not_to raise_error
        end
      end

      context 'when allow_cross_joins_across_databases is used' do
        it 'does not raise exception' do
          expect { main_and_ci_query_allowlisted }.not_to raise_error
        end
      end

      context 'when allow_cross_joins_across_databases is used' do
        it 'does not raise exception' do
          expect { main_and_ci_query_allowlist_nested }.not_to raise_error
        end
      end

      context 'when there is a parser error' do
        it 'does not raise parse PGQuery::ParseError' do
          # Since this is in an invalid query it still raises from ActiveRecord
          # but this tests that we rescue the PGQuery::ParseError which would
          # have otherwise raised first
          expect { ApplicationRecord.connection.execute('SELECT SELECT FROM SELECT') }.to raise_error(ActiveRecord::StatementInvalid)
        end
      end

      context 'when an ALTER INDEX query is used' do
        before do
          ApplicationRecord.connection.execute(<<~SQL)
            CREATE INDEX index_on_projects ON public.projects USING gin (name gin_trgm_ops)
          SQL
        end

        it 'does not raise exception' do
          expect do
            ApplicationRecord.connection.execute('ALTER INDEX index_on_projects SET ( fastupdate = false )')
          end.not_to raise_error
        end
      end
    end
  end

  private

  def main_and_ci_query_allowlisted
    Gitlab::Database.allow_cross_joins_across_databases(url: 'http://issue-url') do
      main_and_ci_query
    end
  end

  def main_and_ci_query_allowlist_nested
    Gitlab::Database.allow_cross_joins_across_databases(url: 'http://issue-url') do
      main_and_ci_query_allowlisted

      main_and_ci_query
    end
  end

  def main_and_ci_allowed_via_annotate
    main_and_ci_query do |relation|
      relation.allow_cross_joins_across_databases(url: 'http://issue-url')
    end
  end

  def main_only_query
    Issue.joins(:project).last
  end

  def ci_only_query
    Ci::Build.joins(:pipeline).last
  end

  def main_and_ci_query
    relation = Ci::Build.joins(:project)
    relation = yield(relation) if block_given?
    relation.last
  end
end
