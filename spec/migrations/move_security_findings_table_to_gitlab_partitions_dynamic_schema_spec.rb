# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MoveSecurityFindingsTableToGitlabPartitionsDynamicSchema, feature_category: :vulnerability_management do
  let(:partitions_sql) do
    <<~SQL
      SELECT
        partitions.relname AS partition_name
      FROM pg_inherits
      JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
      JOIN pg_class partitions ON pg_inherits.inhrelid = partitions.oid
      WHERE
        parent.relname = 'security_findings'
    SQL
  end

  describe '#up' do
    it 'changes the `security_findings` table to be partitioned' do
      expect { migrate! }.to change { security_findings_partitioned? }.from(false).to(true)
                         .and change { execute(partitions_sql) }.from([]).to(['security_findings_1'])
    end
  end

  describe '#down' do
    context 'when there is a partition' do
      let(:users) { table(:users) }
      let(:namespaces) { table(:namespaces) }
      let(:projects) { table(:projects) }
      let(:scanners) { table(:vulnerability_scanners) }
      let(:security_scans) { table(:security_scans) }
      let(:security_findings) { table(:security_findings) }

      let(:user) { users.create!(email: 'test@gitlab.com', projects_limit: 5) }
      let(:namespace) { namespaces.create!(name: 'gtlb', path: 'gitlab', type: Namespaces::UserNamespace.sti_name) }
      let(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, name: 'foo') }
      let(:scanner) { scanners.create!(project_id: project.id, external_id: 'bandit', name: 'Bandit') }
      let(:security_scan) { security_scans.create!(build_id: 1, scan_type: 1) }

      let(:security_findings_count_sql) { 'SELECT COUNT(*) FROM security_findings' }

      before do
        migrate!

        security_findings.create!(
          scan_id: security_scan.id,
          scanner_id: scanner.id,
          uuid: SecureRandom.uuid,
          severity: 0,
          confidence: 0
        )
      end

      it 'creates the original table with the data from the existing partition' do
        expect { schema_migrate_down! }.to change { security_findings_partitioned? }.from(true).to(false)
                                       .and not_change { execute(security_findings_count_sql) }.from([1])
      end

      context 'when there are more than one partitions' do
        before do
          migrate!

          execute(<<~SQL)
            CREATE TABLE gitlab_partitions_dynamic.security_findings_11
            PARTITION OF security_findings FOR VALUES IN (11)
          SQL
        end

        it 'creates the original table from the latest existing partition' do
          expect { schema_migrate_down! }.to change { security_findings_partitioned? }.from(true).to(false)
                                         .and change { execute(security_findings_count_sql) }.from([1]).to([0])
        end
      end
    end

    context 'when there is no partition' do
      before do
        migrate!

        execute(partitions_sql).each do |partition_name|
          execute("DROP TABLE gitlab_partitions_dynamic.#{partition_name}")
        end
      end

      it 'creates the original table' do
        expect { schema_migrate_down! }.to change { security_findings_partitioned? }.from(true).to(false)
      end
    end
  end

  def security_findings_partitioned?
    sql = <<~SQL
      SELECT
        COUNT(*)
      FROM
        pg_partitioned_table
      INNER JOIN pg_class ON pg_class.oid = pg_partitioned_table.partrelid
      WHERE pg_class.relname = 'security_findings'
    SQL

    execute(sql).first != 0
  end

  def execute(sql)
    ActiveRecord::Base.connection.execute(sql).values.flatten
  end
end
