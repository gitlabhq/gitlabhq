# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitionable do
  describe 'partitionable models inclusion' do
    let(:ci_model) { Class.new(Ci::ApplicationRecord) }

    subject { ci_model.include(described_class) }

    it 'raises an exception' do
      expect { subject }
        .to raise_error(/must be included in PARTITIONABLE_MODELS/)
    end

    context 'when is included in the models list' do
      before do
        stub_const("#{described_class}::Testing::PARTITIONABLE_MODELS", [ci_model.name])
      end

      it 'does not raise exceptions' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
