# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::MetadataCache, type: :model, feature_category: :package_registry do
  let_it_be(:npm_metadata_cache) { create(:npm_metadata_cache) }

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:npm_metadata_caches) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:size) }

    describe '#package_name' do
      it { is_expected.to validate_presence_of(:package_name) }
      it { is_expected.to validate_uniqueness_of(:package_name).scoped_to(:project_id) }
      it { is_expected.to allow_value('my.app-11.07.2018').for(:package_name) }
      it { is_expected.to allow_value('@group-1/package').for(:package_name) }
      it { is_expected.to allow_value('@any-scope/package').for(:package_name) }
      it { is_expected.to allow_value('unscoped-package').for(:package_name) }
      it { is_expected.not_to allow_value('my(dom$$$ain)com.my-app').for(:package_name) }
      it { is_expected.not_to allow_value('@inv@lid-scope/package').for(:package_name) }
      it { is_expected.not_to allow_value('@scope/../../package').for(:package_name) }
      it { is_expected.not_to allow_value('@scope%2e%2e%fpackage').for(:package_name) }
      it { is_expected.not_to allow_value('@scope/sub/package').for(:package_name) }
    end
  end
end
