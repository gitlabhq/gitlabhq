# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Helpers::Packages::Npm, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:namespace) { group }
  let_it_be(:project) { create(:project, :public, namespace: namespace) }
  let_it_be(:package) { create(:npm_package, project: project) }

  let(:package_name) { package.name }
  let(:object) { klass.new({}) }
  let(:klass) do
    Struct.new(:params) do
      include ::API::Helpers
      include ::API::Helpers::Packages::Npm
    end
  end

  describe '#enqueue_sync_metadata_cache_worker' do
    it_behaves_like 'enqueue a worker to sync a metadata cache' do
      subject { object.enqueue_sync_metadata_cache_worker(project, package_name) }
    end
  end
end
