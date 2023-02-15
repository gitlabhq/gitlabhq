# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncForeignKeys, feature_category: :database do
  describe '.validate_pending_entries!' do
    subject { described_class.validate_pending_entries! }

    before do
      create_list(:postgres_async_foreign_key_validation, 3)
    end

    it 'takes 2 pending FK validations and executes them' do
      validations = described_class::PostgresAsyncForeignKeyValidation.ordered.limit(2).to_a

      expect_next_instances_of(described_class::ForeignKeyValidator, 2, validations) do |validator|
        expect(validator).to receive(:perform)
      end

      subject
    end
  end
end
