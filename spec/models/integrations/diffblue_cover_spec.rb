# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::DiffblueCover, feature_category: :continuous_integration do
  it_behaves_like Integrations::Base::DiffblueCover
end
