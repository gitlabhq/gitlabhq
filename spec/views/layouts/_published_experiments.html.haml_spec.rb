# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_published_experiments', :experiment do
  before do
    stub_const('TestControlExperiment', ApplicationExperiment)
    stub_const('TestCandidateExperiment', ApplicationExperiment)
    stub_const('TestExcludedExperiment', ApplicationExperiment)

    TestControlExperiment.new('test_control').tap do |e|
      e.variant(:control)
      e.publish
    end
    TestCandidateExperiment.new('test_candidate').tap do |e|
      e.variant(:candidate)
      e.publish
    end
    TestExcludedExperiment.new('test_excluded').tap do |e|
      e.exclude!
      e.publish
    end

    render
  end

  it 'renders out data for all non-excluded, published experiments' do
    output = rendered

    expect(output).to include('gl.experiments = {')
    expect(output).to match(/"test_control":\{[^}]*"variant":"control"/)
    expect(output).to match(/"test_candidate":\{[^}]*"variant":"candidate"/)
    expect(output).not_to include('"test_excluded"')
  end
end
