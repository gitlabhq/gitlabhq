# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Component do
  let(:attributes) do
    {
      type: 'library',
      name: 'component-name',
      version: 'v0.0.1'
    }
  end

  subject { described_class.new(**attributes) }

  it 'has correct attributes' do
    expect(subject).to have_attributes(
      component_type: attributes[:type],
      name: attributes[:name],
      version: attributes[:version]
    )
  end
end
