# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/lib/gitlab/local_and_remote_storage_migration_shared_examples'

RSpec.describe Gitlab::LocalAndRemoteStorageMigration::PagesDeploymentMigrater do
  before do
    stub_pages_object_storage(::Pages::DeploymentUploader, enabled: true)
  end

  let!(:item) { create(:pages_deployment, file_store: start_store) }

  it_behaves_like 'local and remote storage migration'
end
