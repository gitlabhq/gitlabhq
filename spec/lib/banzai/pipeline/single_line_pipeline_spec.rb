# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

RSpec.describe Banzai::Pipeline::SingleLinePipeline, feature_category: :markdown do
  it_behaves_like 'a single line pipeline'
end
