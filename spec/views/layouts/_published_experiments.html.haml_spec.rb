# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_published_experiments', :experiment do
  before do
    # Stub each experiment to be enabled, otherwise tracking does not happen.
    stub_experiments(
      test_control: :control,
      test_excluded: true,
      test_published_only: :control,
      test_candidate: :candidate,
      test_variant: :variant_name
    )

    experiment(:test_control) {}
    experiment(:test_excluded) { |e| e.exclude! }
    experiment(:test_candidate) { |e| e.candidate {} }
    experiment(:test_variant) { |e| e.variant(:variant_name) {} }
    experiment(:test_published_only).publish

    render
  end

  it 'renders out data for all non-excluded, published experiments' do
    output = rendered

    expect(output).to include('gl.experiments = {')
    expect(output).to match(/"test_control":\{[^}]*"variant":"control"/)
    expect(output).not_to include('"test_excluded"')
    expect(output).to match(/"test_candidate":\{[^}]*"variant":"candidate"/)
    expect(output).to match(/"test_variant":\{[^}]*"variant":"variant_name"/)
    expect(output).to match(/"test_published_only":\{[^}]*"variant":"control"/)
  end
end
