# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feature::Shared, feature_category: :tooling do
  describe '.can_be_default_enabled?' do
    subject { described_class.can_be_default_enabled?(type) }

    described_class::TYPES.each do |type, data|
      context "when type is #{type}" do
        let(:type) { type }

        it { is_expected.to eq(data[:can_be_default_enabled]) }
      end
    end
  end
end
