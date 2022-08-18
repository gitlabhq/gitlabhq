# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Component do
  let(:attributes) do
    {
      'type' => 'library',
      'name' => 'component-name',
      'version' => 'v0.0.1'
    }
  end

  subject { described_class.new(attributes) }

  it 'has correct attributes' do
    expect(subject).to have_attributes(
      component_type: 'library',
      name: 'component-name',
      version: 'v0.0.1'
    )
  end
end
