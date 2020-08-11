# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Nuget::Dependency do
  let(:dependency) do
    {
      id: 'http://gitlab.com/Sandbox.App/1.0.0.json#dependency',
      type: 'PackageDependency',
      name: 'Dependency',
      range: '2.0.0'
    }
  end

  let(:expected) do
    {
      '@id': 'http://gitlab.com/Sandbox.App/1.0.0.json#dependency',
      '@type': 'PackageDependency',
      'id': 'Dependency',
      'range': '2.0.0'
    }
  end

  let(:entity) { described_class.new(dependency) }

  subject { entity.as_json }

  it { is_expected.to eq(expected) }
end
