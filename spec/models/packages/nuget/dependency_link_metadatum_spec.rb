# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::DependencyLinkMetadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:dependency_link) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:dependency_link) }
    it { is_expected.to validate_presence_of(:target_framework) }

    describe '#ensure_nuget_package_type' do
      it 'validates package of type nuget' do
        package = build('conan_package')
        dependency_link = build('packages_dependency_link', package: package)
        nuget_metadatum = build('nuget_dependency_link_metadatum', dependency_link: dependency_link)

        expect(nuget_metadatum).not_to be_valid
        expect(nuget_metadatum.errors.to_a).to contain_exactly('Package type must be NuGet')
      end

      it 'validates package of type nuget with nil dependency_link' do
        nuget_metadatum = build('nuget_dependency_link_metadatum', dependency_link: nil)

        expect(nuget_metadatum).not_to be_valid
        expect(nuget_metadatum.errors.to_a).to contain_exactly("Dependency link can't be blank", 'Package type must be NuGet')
      end
    end
  end
end
