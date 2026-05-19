# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Harbor, feature_category: :container_registry do
  it_behaves_like Integrations::Base::Harbor
end
