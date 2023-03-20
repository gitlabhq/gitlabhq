# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncConstraints::Validators, feature_category: :database do
  describe '.for' do
    subject { described_class.for(record) }

    context 'with foreign keys validations' do
      let(:record) { build(:postgres_async_constraint_validation, :foreign_key) }

      it { is_expected.to be_a(described_class::ForeignKey) }
    end

    context 'with check constraint validations' do
      let(:record) { build(:postgres_async_constraint_validation, :check_constraint) }

      it { is_expected.to be_a(described_class::CheckConstraint) }
    end
  end
end
