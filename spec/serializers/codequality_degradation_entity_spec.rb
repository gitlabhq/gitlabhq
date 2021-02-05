# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodequalityDegradationEntity do
  let(:entity) { described_class.new(codequality_degradation) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when codequality contains an error' do
      context 'when line is included in location' do
        let(:codequality_degradation) { build(:codequality_degradation_2) }

        it 'contains correct codequality degradation details', :aggregate_failures do
          expect(subject[:description]).to eq("Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.")
          expect(subject[:severity]).to eq("major")
          expect(subject[:file_path]).to eq("file_a.rb")
          expect(subject[:line]).to eq(10)
        end
      end

      context 'when line is included in positions' do
        let(:codequality_degradation) { build(:codequality_degradation_3) }

        it 'contains correct codequality degradation details', :aggregate_failures do
          expect(subject[:description]).to eq("Avoid parameter lists longer than 5 parameters. [12/5]")
          expect(subject[:severity]).to eq("minor")
          expect(subject[:file_path]).to eq("file_b.rb")
          expect(subject[:line]).to eq(10)
        end
      end
    end
  end
end
