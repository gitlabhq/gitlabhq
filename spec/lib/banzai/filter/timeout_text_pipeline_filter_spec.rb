# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TimeoutTextPipelineFilter, feature_category: :team_planning do
  include FilterSpecHelper

  it_behaves_like 'text filter timeout' do
    let(:text) { '<p>some text</p>' }
  end

  it 'raises NotImplementedError' do
    expect { filter('test') }.to raise_error NotImplementedError
  end
end
