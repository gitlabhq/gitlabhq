# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe 'ci:backfill_catalog_bundles', feature_category: :pipeline_composition do
  let(:task_class) { Tasks::Ci::BackfillCatalogBundlesTask }
  let(:task) { instance_double(task_class) }

  before do
    Rake.application.rake_require('tasks/ci/backfill_catalog_bundles')
  end

  it 'invokes Tasks::Ci::BackfillCatalogBundlesTask#execute' do
    expect(task_class).to receive(:new).and_return(task)
    expect(task).to receive(:execute)

    run_rake_task('ci:backfill_catalog_bundles')
  end
end
