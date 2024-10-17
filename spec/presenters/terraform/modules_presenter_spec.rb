# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Terraform::ModulesPresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:module_system) { 'my-system' }
  let_it_be(:package_name) { "my-module/#{module_system}" }
  let_it_be(:package1) { create(:terraform_module_package, version: '1.0.1', project: project, name: package_name) }
  let_it_be(:package2) { create(:terraform_module_package, version: '1.0.10', project: project, name: package_name) }

  let(:packages) { ::Packages::TerraformModule::Package.for_projects(project).with_name(package_name) }
  let(:presenter) { described_class.new(packages, module_system) }

  describe '#modules' do
    subject { presenter.modules }

    it { is_expected.to be_an(Array) }
    it { expect(subject.first).to be_a(Hash) }
    it { expect(subject).to match_schema('public_api/v4/packages/terraform/modules/v1/modules') }
  end
end
