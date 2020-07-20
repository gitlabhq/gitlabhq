# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Maven::FindOrCreatePackageService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:app_name) { 'my-app' }
  let_it_be(:version) { '1.0-SNAPSHOT' }
  let_it_be(:path) { "my/company/app/#{app_name}" }
  let_it_be(:path_with_version) { "#{path}/#{version}" }
  let_it_be(:params) do
    {
      path: path_with_version,
      name: path,
      version: version
    }
  end

  describe '#execute' do
    subject { described_class.new(project, user, params).execute }

    context 'without any existing package' do
      it 'creates a package' do
        expect { subject }.to change { Packages::Package.count }.by(1)
      end
    end

    context 'with an existing package' do
      let_it_be(:existing_package) { create(:maven_package, name: path, version: version, project: project) }

      it { is_expected.to eq existing_package }
      it "doesn't create a new package" do
        expect { subject }
          .to not_change { Packages::Package.count }
      end
    end
  end
end
