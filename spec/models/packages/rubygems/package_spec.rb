# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::Package, type: :model, feature_category: :package_registry do
  let_it_be(:rubygems_package) { build_stubbed(:rubygems_package) }

  describe 'associations' do
    it { is_expected.to have_one(:rubygems_metadatum).inverse_of(:package).class_name('Packages::Rubygems::Metadatum') }
  end

  describe 'validations' do
    describe '#name' do
      it_behaves_like 'validate package name format', :rubygems_package
    end
  end

  describe '.installable' do
    it_behaves_like 'installable packages', :rubygems_package
  end

  describe '.installable_for_project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:installable_package) { create(:rubygems_package, project: project) }
    let_it_be(:other_project_package) { create(:rubygems_package, project: other_project) }
    let_it_be(:error_package) { create(:rubygems_package, :error, project: project) }
    let_it_be(:processing_package) { create(:rubygems_package, :processing, project: project) }
    let_it_be(:versionless_package) { create(:rubygems_package, project: project, version: nil) }

    subject { described_class.installable_for_project(project) }

    it 'returns only installable packages with a version for the given project', :aggregate_failures do
      is_expected.to contain_exactly(installable_package)
      is_expected.not_to include(other_project_package, error_package, processing_package, versionless_package)
    end
  end

  describe '#sync_rubygems_spec_files' do
    it 'enqueues a CreateSpecFilesWorker job for the package project' do
      expect(::Packages::Rubygems::CreateSpecFilesWorker)
        .to receive(:perform_async).with(rubygems_package.project_id)

      rubygems_package.sync_rubygems_spec_files
    end
  end
end
