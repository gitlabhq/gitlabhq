# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::CleanupManifestWorker, feature_category: :virtual_registry do
  let_it_be(:factory_type) { :dependency_proxy_manifest }

  it_behaves_like 'dependency_proxy_cleanup_worker'
end
