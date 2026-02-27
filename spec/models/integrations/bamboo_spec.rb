# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Bamboo, :use_clean_rails_memory_store_caching, feature_category: :continuous_integration do
  it_behaves_like Integrations::Base::Bamboo
end
