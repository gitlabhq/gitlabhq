# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CrossDatabaseModification do
  describe '.transaction' do
    it 'adds the current gitlab schema to gitlab_transactions_stack', :aggregate_failures do
      ApplicationRecord.transaction do
        expect(ApplicationRecord.gitlab_transactions_stack).to contain_exactly(:gitlab_main)

        Project.first
      end

      expect(ApplicationRecord.gitlab_transactions_stack).to be_empty

      Ci::ApplicationRecord.transaction do
        expect(ApplicationRecord.gitlab_transactions_stack).to contain_exactly(:gitlab_ci)

        Project.first
      end

      expect(ApplicationRecord.gitlab_transactions_stack).to be_empty

      PackageMetadata::ApplicationRecord.transaction do
        expect(ApplicationRecord.gitlab_transactions_stack).to contain_exactly(:gitlab_pm)

        Project.first
      end

      expect(ApplicationRecord.gitlab_transactions_stack).to be_empty

      Project.transaction do
        expect(ApplicationRecord.gitlab_transactions_stack).to contain_exactly(:gitlab_main_cell)

        Project.first
      end

      expect(ApplicationRecord.gitlab_transactions_stack).to be_empty

      Ci::Pipeline.transaction do
        expect(ApplicationRecord.gitlab_transactions_stack).to contain_exactly(:gitlab_ci)

        Project.first
      end

      expect(ApplicationRecord.gitlab_transactions_stack).to be_empty

      ApplicationRecord.transaction do
        expect(ApplicationRecord.gitlab_transactions_stack).to contain_exactly(:gitlab_main)

        Ci::Pipeline.transaction do
          expect(ApplicationRecord.gitlab_transactions_stack).to contain_exactly(:gitlab_main, :gitlab_ci)

          Project.first
        end
      end

      expect(ApplicationRecord.gitlab_transactions_stack).to be_empty
    end

    it 'yields' do
      expect { |block| ApplicationRecord.transaction(&block) }.to yield_control
    end
  end
end
