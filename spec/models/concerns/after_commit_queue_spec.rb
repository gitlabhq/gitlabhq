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
  end
end
