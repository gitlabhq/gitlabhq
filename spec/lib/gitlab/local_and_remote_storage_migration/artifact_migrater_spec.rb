# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/lib/gitlab/local_and_remote_storage_migration_shared_examples'

RSpec.describe Gitlab::LocalAndRemoteStorageMigration::ArtifactMigrater do
  before do
    stub_artifacts_object_storage(enabled: true)
  end

  let!(:item) { create(:ci_job_artifact, :archive, file_store: start_store) }

  it_behaves_like 'local and remote storage migration'
end
