# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Requests on a read-only node', feature_category: :database do
  context 'when db is read-only' do
    before do
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

    it_behaves_like 'graphql on a read-only GitLab instance'
  end
end
