# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncConstraints, feature_category: :database do
  describe '.validate_pending_entries!' do
    subject { described_class.validate_pending_entries! }

    let!(:fk_validation) do
      create(:postgres_async_constraint_validation, :foreign_key, attempts: 2)
    end

    let(:check_validation) do
      create(:postgres_async_constraint_validation, :check_constraint, attempts: 1)
    end

    it 'executes pending validations' do
      expect_next_instance_of(described_class::Validators::ForeignKey, fk_validation) do |validator|
        expect(validator).to receive(:perform)
      end

      expect_next_instance_of(described_class::Validators::CheckConstraint, check_validation) do |validator|
        expect(validator).to receive(:perform)
      end

      subject
    end
  end
end
