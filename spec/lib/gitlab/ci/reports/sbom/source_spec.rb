# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Source do
  let(:attributes) do
    {
      'type' => :dependency_file,
      'data' => {
        'input_file' => { 'name' => 'package-lock.json' },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      },
      'fingerprint' => '4ee1623c8f3ddd152b3c1fc340b3ece3cbcf807efa2726307ea34e7d6d36a6c1'
    }
  end

  subject { described_class.new(**attributes) }

  it 'has correct attributes' do
    expect(subject).to have_attributes(
      source_type: :dependency_file,
      data: {
        'input_file' => { 'name' => 'package-lock.json' },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      },
      fingerprint: '4ee1623c8f3ddd152b3c1fc340b3ece3cbcf807efa2726307ea34e7d6d36a6c1'
    )
  end
end
