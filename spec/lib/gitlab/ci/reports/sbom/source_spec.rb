# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Source, feature_category: :dependency_management do
  let(:attributes) do
    {
      type: :dependency_scanning,
      data: {
        'category' => 'development',
        'input_file' => { 'path' => 'package-lock.json' },
        'source_file' => { 'path' => 'package.json' },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      }
    }
  end

  subject { described_class.new(**attributes) }

  it 'has correct attributes' do
    expect(subject).to have_attributes(
      source_type: attributes[:type],
      data: attributes[:data]
    )
  end
end
