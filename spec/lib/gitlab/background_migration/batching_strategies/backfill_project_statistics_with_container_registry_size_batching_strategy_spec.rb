# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::BackfillProjectStatisticsWithContainerRegistrySizeBatchingStrategy do # rubocop:disable Layout/LineLength
  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy }
end
