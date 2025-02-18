# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Ewm, feature_category: :integrations do
  it_behaves_like Integrations::Base::Ewm
end
