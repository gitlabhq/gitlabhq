# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::CleanupBlobWorker, feature_category: :virtual_registry do
  let_it_be(:factory_type) { :dependency_proxy_blob }

  it_behaves_like 'dependency_proxy_cleanup_worker'
end
