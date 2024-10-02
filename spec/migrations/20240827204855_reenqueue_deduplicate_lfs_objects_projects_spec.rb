# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReenqueueDeduplicateLfsObjectsProjects, feature_category: :source_code_management do
  let(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    migrate!
    expect(batched_migration).not_to have_scheduled_batched_migration
  end
end
