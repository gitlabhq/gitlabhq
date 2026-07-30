# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Siphon::SetupTask, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }
  let(:publication) { 'siphon_spec_pub' }
  let(:table) { 'plan_limits' }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/siphon/setup'
  end

  before do
    connection.execute(described_class::ALTER_PUBLICATION_FUNCTION)
    connection.execute("CREATE PUBLICATION #{publication}")
  end

  def alter_publication(pbl, tbl, op)
    connection.select_value(
      "SELECT public.siphon_alter_publication(#{connection.quote(pbl)}, #{connection.quote(tbl)}, #{op})"
    )
  end

  def published_tables
    connection.select_values(
      "SELECT tablename FROM pg_publication_tables WHERE pubname = #{connection.quote(publication)}"
    )
  end

  describe 'the happy path' do
    it 'adds and removes a table', :aggregate_failures do
      alter_publication(publication, "public.#{table}", 0)
      expect(published_tables).to contain_exactly(table)

      alter_publication(publication, "public.#{table}", 1)
      expect(published_tables).to be_empty
    end
  end

  describe 'input validation' do
    bad_publication = /Invalid publication name/
    bad_table = /Invalid table name format/

    {
      'injection via the publication name' => ['x; DROP TABLE plan_limits; --', 'public.plan_limits', 0,
        bad_publication],
      'a quoted publication name' => [%q(x' OR '1'='1), 'public.plan_limits', 0, bad_publication],
      'injection via the table name' => ['siphon_spec_pub', 'public.plan_limits; DROP TABLE plan_limits', 0,
        bad_table],
      'an unqualified table name' => ['siphon_spec_pub', 'plan_limits', 0, bad_table],
      'a three-part table name' => ['siphon_spec_pub', 'db.public.plan_limits', 0, bad_table],
      'a comment-terminated table name' => ['siphon_spec_pub', 'public.plan_limits --', 0, bad_table],
      'an out-of-range operation' => ['siphon_spec_pub', 'public.plan_limits', 2, /Invalid operation parameter/]
    }.each do |case_name, (pbl, tbl, op, message)|
      it "rejects #{case_name}" do
        expect { alter_publication(pbl, tbl, op) }
          .to raise_error(ActiveRecord::StatementInvalid, message)
      end
    end

    it 'leaves the database untouched after a rejected injection attempt', :aggregate_failures do
      expect do
        connection.transaction(requires_new: true) do
          alter_publication(publication, "public.#{table}; DROP TABLE #{table}", 0)
        end
      end.to raise_error(ActiveRecord::StatementInvalid)

      expect(connection.table_exists?(table)).to be(true)
      expect(published_tables).to be_empty
    end
  end
end
