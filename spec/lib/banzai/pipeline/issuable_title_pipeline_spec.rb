# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

RSpec.describe Banzai::Pipeline::IssuableTitlePipeline, feature_category: :markdown do
  it_behaves_like 'a single line pipeline' do
    it 'processes backticks' do
      text = 'hello `friend`'

      expect(to_html(text)).to eq_html('hello <code>friend</code>')
    end

    def to_html(text)
      described_class.to_html(text, project: project, pipeline: :issuable_title)
    end
  end
end
