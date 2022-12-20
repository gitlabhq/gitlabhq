# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TimeoutHtmlPipelineFilter do
  include FilterSpecHelper

  it_behaves_like 'filter timeout' do
    let(:text) { '<p>some text</p>' }
  end

  it 'raises NotImplementedError' do
    expect { filter('test') }.to raise_error NotImplementedError
  end
end
