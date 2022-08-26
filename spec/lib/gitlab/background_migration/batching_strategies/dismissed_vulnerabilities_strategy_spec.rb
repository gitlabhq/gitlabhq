# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::DismissedVulnerabilitiesStrategy, '#next_batch' do
  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy }
end
