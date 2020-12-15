# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UUID do
  let_it_be(:name) { "GitLab" }

  describe '.v5' do
    subject { described_class.v5(name) }

    before do
      # This is necessary to clear memoization for testing different environments
      described_class.instance_variable_set(:@default_namespace_id, nil)
    end

    context 'in development' do
      let_it_be(:development_proper_uuid) { "5b593e54-90f5-504b-8805-5394a4d14b94" }

      before do
        allow(Rails).to receive(:env).and_return(:development)
      end

      it { is_expected.to eq(development_proper_uuid) }
    end

    context 'in test' do
      let_it_be(:test_proper_uuid) { "5b593e54-90f5-504b-8805-5394a4d14b94" }

      it { is_expected.to eq(test_proper_uuid) }
    end

    context 'in staging' do
      let_it_be(:staging_proper_uuid) { "dd190b37-7754-5c7c-80a0-85621a5823ad" }

      before do
        allow(Rails).to receive(:env).and_return(:staging)
      end

      it { is_expected.to eq(staging_proper_uuid) }
    end

    context 'in production' do
      let_it_be(:production_proper_uuid) { "4961388b-9d8e-5da0-a499-3ef5da58daf0" }

      before do
        allow(Rails).to receive(:env).and_return(:production)
      end

      it { is_expected.to eq(production_proper_uuid) }
    end
  end
end
