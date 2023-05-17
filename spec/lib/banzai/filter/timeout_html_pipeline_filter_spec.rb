# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TimeoutHtmlPipelineFilter, feature_category: :team_planning do
  include FilterSpecHelper

  it_behaves_like 'html filter timeout' do
    let(:text) { '<p>some text</p>' }
  end

  it 'raises NotImplementedError' do
    expect { filter('test') }.to raise_error NotImplementedError
  end
end
