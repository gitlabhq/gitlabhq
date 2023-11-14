# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedJobTransitionLog, type: :model do
  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe 'associations' do
    it { is_expected.to belong_to(:batched_job).with_foreign_key(:batched_background_migration_job_id) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:previous_status) }
    it { is_expected.to validate_presence_of(:next_status) }
    it { is_expected.to validate_presence_of(:batched_job) }
    it { is_expected.to validate_length_of(:exception_class).is_at_most(100) }
    it { is_expected.to validate_length_of(:exception_message).is_at_most(1000) }
    it { is_expected.to define_enum_for(:previous_status).with_values(%i[pending running failed succeeded]).with_prefix }
    it { is_expected.to define_enum_for(:next_status).with_values(%i[pending running failed succeeded]).with_prefix }
  end
end
