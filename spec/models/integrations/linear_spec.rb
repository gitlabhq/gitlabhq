# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Linear, :use_clean_rails_memory_store_caching, feature_category: :integrations do
  it_behaves_like Integrations::Base::Linear
end
