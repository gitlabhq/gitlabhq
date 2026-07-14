# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::CreateDependenciesService, feature_category: :package_registry do
  include RubygemsHelpers

  let_it_be(:package) { create(:rubygems_package) }
  let_it_be(:package_file) { create(:package_file, :gem) }
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:gem, freeze: false) { gem_from_file(package_file.file) }
  let_it_be(:gemspec, freeze: false) { gem.spec }

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
