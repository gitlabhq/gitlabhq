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

  describe '#enqueue_sync_npm_metadata_cache_worker' do
    it_behaves_like 'enqueue a worker to sync a npm metadata cache' do
      subject { object.enqueue_sync_npm_metadata_cache_worker(project, package_name) }
    end
  end

  describe '#version_from_filename' do
    it 'parses the version from an unscoped filename' do
      expect(object.version_from_filename('lodash', 'lodash-4.17.21.tgz')).to eq('4.17.21')
    end

    it 'parses the version from a scoped filename (filename is unscoped)' do
      expect(object.version_from_filename('@babel/core', 'core-7.0.0.tgz')).to eq('7.0.0')
    end

    it 'returns nil when the filename does not match the package name' do
      expect(object.version_from_filename('lodash', 'evil-1.0.0.tgz')).to be_nil
    end

    it 'returns nil for a blank version' do
      expect(object.version_from_filename('lodash', 'lodash-.tgz')).to be_nil
    end

    it 'returns nil when the filename does not end in .tgz' do
      expect(object.version_from_filename('lodash', 'lodash-4.17.21.tar.gz')).to be_nil
    end
  end
end
