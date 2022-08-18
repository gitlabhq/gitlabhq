# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Source do
  let(:attributes) do
    {
      'type' => :dependency_scanning,
      'data' => {
        'category' => 'development',
        'input_file' => { 'path' => 'package-lock.json' },
        'source_file' => { 'path' => 'package.json' },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      },
      'fingerprint' => '4dbcb747e6f0fb3ed4f48d96b777f1d64acdf43e459fdfefad404e55c004a188'
    }
  end

  subject { described_class.new(attributes) }

  it 'has correct attributes' do
    expect(subject).to have_attributes(
      source_type: attributes['type'],
      data: attributes['data'],
      fingerprint: attributes['fingerprint']
    )
  end
end
