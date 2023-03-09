# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::CreateTemporaryPackageService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:params) { {} }
  let_it_be(:package_name) { 'my-package' }
  let_it_be(:package_type) { 'rubygems' }

  describe '#execute' do
    subject { described_class.new(project, user, params).execute(package_type, name: package_name) }

    let(:package) { Packages::Package.last }

    it 'creates the package', :aggregate_failures do
      expect { subject }.to change { Packages::Package.count }.by(1)

      expect(package).to be_valid
      expect(package).to be_processing
      expect(package.name).to eq(package_name)
      expect(package.version).to start_with(described_class::PACKAGE_VERSION)
      expect(package.package_type).to eq(package_type)
    end

    it 'can create two packages in a row', :aggregate_failures do
      expect { subject }.to change { Packages::Package.count }.by(1)

      expect do
        described_class.new(project, user, params).execute(package_type, name: package_name)
      end.to change { Packages::Package.count }.by(1)

      expect(package).to be_valid
      expect(package).to be_processing
      expect(package.name).to eq(package_name)
      expect(package.version).to start_with(described_class::PACKAGE_VERSION)
      expect(package.package_type).to eq(package_type)
    end

    it_behaves_like 'assigns the package creator'
    it_behaves_like 'assigns build to package'
  end
end
