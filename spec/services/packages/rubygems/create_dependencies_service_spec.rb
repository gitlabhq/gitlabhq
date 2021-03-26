# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rubygems::CreateDependenciesService do
  include RubygemsHelpers

  let_it_be(:package) { create(:rubygems_package) }
  let_it_be(:package_file) { create(:package_file, :gem) }
  let_it_be(:gem) { gem_from_file(package_file.file) }
  let_it_be(:gemspec) { gem.spec }

  let(:service) { described_class.new(package, gemspec) }

  describe '#execute' do
    subject { service.execute }

    it 'creates dependencies', :aggregate_failures do
      expect { subject }.to change { Packages::Dependency.count }.by(4)

      gemspec.dependencies.each do |dependency|
        persisted_dependency = Packages::Dependency.find_by(name: dependency.name)

        expect(persisted_dependency.version_pattern).to eq dependency.requirement.to_s
      end
    end

    it 'links dependencies to the package' do
      expect { subject }.to change { package.dependency_links.count }.by(4)

      expect(package.dependency_links.first).to be_dependencies
    end
  end
end
