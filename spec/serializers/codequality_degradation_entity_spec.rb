# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodequalityDegradationEntity, feature_category: :code_quality do
  let(:entity) { described_class.new(codequality_degradation) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when codequality contains an error' do
      context 'when line is included in location' do
        let(:codequality_degradation) { build(:codequality_degradation_2) }

        it 'contains correct codequality degradation details', :aggregate_failures do
          expect(subject[:description]).to eq("Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.")
          expect(subject[:fingerprint]).to eq("f3bdc1e8c102ba5fbd9e7f6cda51c95e")
          expect(subject[:severity]).to eq("major")
          expect(subject[:file_path]).to eq("file_a.rb")
          expect(subject[:line]).to eq(10)
          expect(subject[:web_url]).to eq("http://localhost/root/test-project/-/blob/f572d396fae9206628714fb2ce00f72e94f2258f/file_a.rb#L10")
          expect(subject[:engine_name]).to eq('structure')
        end
      end

      context 'when line is included in positions' do
        let(:codequality_degradation) { build(:codequality_degradation_3) }

        it 'contains correct codequality degradation details', :aggregate_failures do
          expect(subject[:description]).to eq("Avoid parameter lists longer than 5 parameters. [12/5]")
          expect(subject[:fingerprint]).to eq("ab5f8b935886b942d621399f5a2ca16e")
          expect(subject[:severity]).to eq("minor")
          expect(subject[:file_path]).to eq("file_b.rb")
          expect(subject[:line]).to eq(10)
          expect(subject[:web_url]).to eq("http://localhost/root/test-project/-/blob/f572d396fae9206628714fb2ce00f72e94f2258f/file_b.rb#L10")
          expect(subject[:engine_name]).to eq('rubocop')
        end
      end

      context 'when severity is capitalized' do
        let(:codequality_degradation) { build(:codequality_degradation_3) }

        before do
          codequality_degradation[:severity] = 'MINOR'
        end

        it 'lowercases severity', :aggregate_failures do
          expect(subject[:description]).to eq("Avoid parameter lists longer than 5 parameters. [12/5]")
          expect(subject[:fingerprint]).to eq("ab5f8b935886b942d621399f5a2ca16e")
          expect(subject[:severity]).to eq("minor")
          expect(subject[:file_path]).to eq("file_b.rb")
          expect(subject[:line]).to eq(10)
          expect(subject[:web_url]).to eq("http://localhost/root/test-project/-/blob/f572d396fae9206628714fb2ce00f72e94f2258f/file_b.rb#L10")
          expect(subject[:engine_name]).to eq('rubocop')
        end
      end

      context 'when severity is a non-codeclimate-standard severity' do
        # See standard severities: https://docs.codeclimate.com/docs/issues#issue-severity
        let(:codequality_degradation) { build(:codequality_degradation_3) }

        it 'returns severity as unknown', :aggregate_failures do
          codequality_degradation[:severity] = 'warning'

          expect(subject[:severity]).to eq('unknown')
        end
      end
    end
  end
end
