# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CrossDatabaseModification do
  describe '.transaction' do
    context 'feature flag disabled' do
      before do
        stub_feature_flags(track_gitlab_schema_in_current_transaction: false)
      end

      it 'does not add to gitlab_transactions_stack' do
        ApplicationRecord.transaction do
          expect(ApplicationRecord.gitlab_transactions_stack).to be_empty

          Project.first
        end

        expect(ApplicationRecord.gitlab_transactions_stack).to be_empty
      end
    end

    context 'feature flag is not yet setup' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_raise(ActiveRecord::NoDatabaseError)
      end

      it 'does not add to gitlab_transactions_stack' do
        ApplicationRecord.transaction do
          expect(ApplicationRecord.gitlab_transactions_stack).to be_empty

          Project.first
        end

        expect(ApplicationRecord.gitlab_transactions_stack).to be_empty
      end
    end

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

      Project.transaction do
        expect(ApplicationRecord.gitlab_transactions_stack).to contain_exactly(:gitlab_main)

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
