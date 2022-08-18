# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigrationWorker do
  it_behaves_like 'it runs batched background migration jobs', :main, :events
end
