# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Nuget::DependencyGroup do
  let(:dependency_group) do
    {
      id: 'http://gitlab.com/Sandbox.App/1.0.0.json#dependencygroup',
      type: 'PackageDependencyGroup',
      target_framework: 'fwk test',
      dependencies: [
        {
          id: 'http://gitlab.com/Sandbox.App/1.0.0.json#dependency',
          type: 'PackageDependency',
          name: 'Dependency',
          range: '2.0.0'
        }
      ]
    }
  end

  let(:expected) do
    {
      '@id': 'http://gitlab.com/Sandbox.App/1.0.0.json#dependencygroup',
      '@type': 'PackageDependencyGroup',
      'targetFramework': 'fwk test',
      'dependencies': [
        {
          '@id': 'http://gitlab.com/Sandbox.App/1.0.0.json#dependency',
          '@type': 'PackageDependency',
          'id': 'Dependency',
          'range': '2.0.0'
        }
      ]
    }
  end

  let(:entity) { described_class.new(dependency_group) }

  subject { entity.as_json }

  it { is_expected.to eq(expected) }

  context 'dependency group without target framework' do
    let(:dependency_group_with_no_target_framework) { dependency_group.tap { |dg| dg[:target_framework] = nil } }
    let(:expected_no_target_framework) { expected.except(:targetFramework) }
    let(:entity) { described_class.new(dependency_group_with_no_target_framework) }

    it { is_expected.to eq(expected_no_target_framework) }
  end
end
