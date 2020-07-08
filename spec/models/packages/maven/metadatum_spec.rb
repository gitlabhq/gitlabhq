# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Maven::Metadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }

    describe '#app_name' do
      it { is_expected.to allow_value("my-app").for(:app_name) }
      it { is_expected.not_to allow_value("my/app").for(:app_name) }
      it { is_expected.not_to allow_value("my(app)").for(:app_name) }
    end

    describe '#app_group' do
      it { is_expected.to allow_value("my.domain.com").for(:app_group) }
      it { is_expected.not_to allow_value("my/domain/com").for(:app_group) }
      it { is_expected.not_to allow_value("my(domain)").for(:app_group) }
    end

    describe '#path' do
      it { is_expected.to allow_value("my/domain/com/my-app").for(:path) }
      it { is_expected.to allow_value("my/domain/com/my-app/1.0-SNAPSHOT").for(:path) }
      it { is_expected.not_to allow_value("my(domain)com.my-app").for(:path) }
    end

    describe '#maven_package_type' do
      it 'will not allow a package with a different package_type' do
        package = build('conan_package')
        maven_metadatum = build('maven_metadatum', package: package)

        expect(maven_metadatum).not_to be_valid
        expect(maven_metadatum.errors.to_a).to include('Package type must be Maven')
      end
    end
  end
end
