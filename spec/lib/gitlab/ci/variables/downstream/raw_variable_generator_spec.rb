# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Variables::Downstream::RawVariableGenerator, feature_category: :ci_variables do
  let(:context) { Gitlab::Ci::Variables::Downstream::Generator::Context.new }

  subject(:generator) { described_class.new(context) }

  describe '#for' do
    it 'returns an array containing the unexpanded raw variable' do
      var = Gitlab::Ci::Variables::Collection::Item.fabricate({ key: 'VAR1', value: '$REF1', raw: true })

      expect(generator.for(var)).to match_array([{ key: 'VAR1', value: '$REF1', raw: true }])
    end
  end
end
