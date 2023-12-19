# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AcmeChallengesController, type: :request, feature_category: :pages do
  it_behaves_like 'Base action controller' do
    subject(:request) { get acme_challenge_path }
  end
end
