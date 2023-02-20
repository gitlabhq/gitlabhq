# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AfterCommitQueue do
  describe '#run_after_commit' do
    it 'runs after record is saved' do
      called = false
      test_proc = proc { called = true }

      project = build(:project)
      project.run_after_commit(&test_proc)

      expect(called).to be false

      # save! is run in its own transaction
      project.save!

      expect(called).to be true
    end

    it 'runs after transaction is committed' do
      called = false
      test_proc = proc { called = true }

      project = build(:project)

      Project.transaction do
        project.run_after_commit(&test_proc)

        project.save!

        expect(called).to be false
      end

      expect(called).to be true
    end
  end

  describe '#run_after_commit_or_now' do
    it 'runs immediately if not within a transction' do
      called = false
      test_proc = proc { called = true }

      project = build(:project)

      project.run_after_commit_or_now(&test_proc)

      expect(called).to be true
    end

    it 'runs after transaction has completed' do
      called = false
      test_proc = proc { called = true }

      project = build(:project)

      Project.transaction do
        # Add this record to the current transaction so that after commit hooks
        # are called
        Project.connection.add_transaction_record(project)

        project.run_after_commit_or_now(&test_proc)

        project.save!

        expect(called).to be false
      end

      expect(called).to be true
    end

    context 'multiple databases - Ci::ApplicationRecord models' do
      before do
        skip_if_multiple_databases_not_setup(:ci)

        table_sql = <<~SQL
          CREATE TABLE _test_gitlab_ci_after_commit_queue (
            id serial NOT NULL PRIMARY KEY);
        SQL

        ::Ci::ApplicationRecord.connection.execute(table_sql)
      end

      let(:ci_klass) do
        Class.new(Ci::ApplicationRecord) do
          self.table_name = '_test_gitlab_ci_after_commit_queue'

          include AfterCommitQueue

          def self.name
            'TestCiAfterCommitQueue'
          end
        end
      end

      let(:ci_record) { ci_klass.new }

      it 'runs immediately if not within a transaction' do
        called = false
        test_proc = proc { called = true }

        ci_record.run_after_commit_or_now(&test_proc)

        expect(called).to be true
      end

      it 'runs after transaction has completed' do
        called = false
        test_proc = proc { called = true }

        Ci::ApplicationRecord.transaction do
          # Add this record to the current transaction so that after commit hooks
          # are called
          Ci::ApplicationRecord.connection.add_transaction_record(ci_record)

          ci_record.run_after_commit_or_now(&test_proc)

          ci_record.save!

          expect(called).to be false
        end

        expect(called).to be true
      end
    end
  end
end
