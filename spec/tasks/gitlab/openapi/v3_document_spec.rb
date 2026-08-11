# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Tasks::Gitlab::Openapi::V3Document, feature_category: :api do
  # Stand-in for a class that is not loaded under fast_spec_helper, so the double stays verified.
  let(:generator_class) { Class.new { def generate; end } }

  let(:generated_spec) do
    {
      'openapi' => '3.0.0',
      'tags' => [
        { 'name' => 'Access requests', 'description' => 'Generated from the Grape class name.' },
        { 'name' => 'Wikis', 'description' => 'Generated from the Grape class name.' }
      ]
    }
  end

  subject(:document) { described_class.new.render }

  before do
    stub_const('Grape::API::Instance', Class.new)
    stub_const('API::Base', Class.new { def self.descendants; end })
    allow(::API::Base).to receive(:descendants).and_return([])

    stub_const('Gitlab::GrapeOpenapi::Generator', Class.new)
    allow(::Gitlab::GrapeOpenapi::Generator).to receive(:new).and_return(
      instance_double(generator_class, generate: generated_spec)
    )
  end

  def rendered_tags
    YAML.safe_load(document)['tags']
  end

  it 'prepends the generated-file header' do
    expect(document).to start_with(described_class::INTRODUCTION)
  end

  it 'renders the generated document below the header' do
    expect(rendered_tags).to eq(generated_spec['tags'])
  end
end
