# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Instance::Teamcity, :use_clean_rails_memory_store_caching, feature_category: :integrations do
  it_behaves_like Integrations::Base::Teamcity do
    let_it_be(:project) { nil }

    subject(:integration) do
      described_class.create!(
        properties: {
          teamcity_url: teamcity_url,
          username: 'mic',
          password: 'password',
          build_type: 'foo'
        }
      )
    end
  end
end
