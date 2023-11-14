# frozen_string_literal: true

module PreventSetOperatorMismatchHelper
  extend ActiveSupport::Concern

  included do
    before do
      stub_const('Type', Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::Type)
    end
  end

  def sql_select_node(sql)
    parsed = PgQuery.parse(sql)
    parsed.tree.stmts[0].stmt.select_stmt
  end
end
