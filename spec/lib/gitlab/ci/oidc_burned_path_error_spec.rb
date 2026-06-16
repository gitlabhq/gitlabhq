# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../lib/gitlab/ci/oidc_burned_path_error'

RSpec.describe Gitlab::Ci::OidcBurnedPathError, feature_category: :continuous_integration do
  describe '#message' do
    it 'returns the default message when none is provided' do
      expect(described_class.new.message).to eq(described_class::MESSAGE)
    end

    it 'includes the recovery instructions', :aggregate_failures do
      expect(described_class.new.message).to include('id_token_sub_claim_components')
      expect(described_class.new.message).to include('project_id')
      expect(described_class.new.message).to include('instance administrator')
    end

    it 'accepts a custom message' do
      expect(described_class.new('custom').message).to eq('custom')
    end
  end

  it 'is a StandardError subclass' do
    expect(described_class.ancestors).to include(StandardError)
  end
end
