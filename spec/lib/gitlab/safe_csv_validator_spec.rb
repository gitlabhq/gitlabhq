# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::SafeCsvValidator, feature_category: :shared do # rubocop:disable RSpec/FeatureCategory -- Shared utility class, not bound to a single category
  describe '#validate!' do
    let(:options) { {} }

    subject(:validate) { described_class.new(options).validate!(raw_csv) }

    context 'with nil input' do
      let(:raw_csv) { nil }

      it 'returns nil without raising' do
        expect(validate).to be_nil
      end
    end

    context 'with empty input' do
      let(:raw_csv) { '' }

      it 'returns nil without raising' do
        expect(validate).to be_nil
      end
    end

    context 'with whitespace-only input that exceeds the size limit' do
      let(:options) { { max_size: 16 } }
      let(:raw_csv) { ' ' * 17 }

      it 'still raises SizeLimitError' do
        expect { validate }.to raise_error(described_class::SizeLimitError)
      end
    end

    context 'when no options are passed' do
      subject(:validate) { described_class.new.validate!(raw_csv) }

      context 'with a CSV well under all defaults' do
        let(:raw_csv) { "a,b,c\n1,2,3\n" }

        it 'does not raise' do
          expect { validate }.not_to raise_error
        end
      end

      context 'with a CSV that exceeds the default :max_size' do
        let(:raw_csv) { 'a' * (described_class::DEFAULTS[:max_size] + 1) }

        it 'raises SizeLimitError using the default limit' do
          expect { validate }.to raise_error(described_class::SizeLimitError)
        end
      end

      context 'with a CSV header that exceeds the default :max_header_columns' do
        let(:raw_csv) { "#{'col,' * described_class::DEFAULTS[:max_header_columns]}col\n" }

        it 'raises HeaderColumnLimitError using the default limit' do
          expect { validate }.to raise_error(described_class::HeaderColumnLimitError)
        end
      end
    end

    context 'when overriding a single default to nil to disable that check' do
      context 'when :max_size is disabled' do
        let(:options) { { max_size: nil } }
        let(:raw_csv) { 'a' * (described_class::DEFAULTS[:max_size] + 1) }

        it 'skips the size check (other defaults still apply)' do
          expect { validate }.not_to raise_error
        end
      end

      context 'when :max_delimiters is disabled' do
        let(:options) { { max_delimiters: nil } }
        let(:raw_csv) { "a,b\n#{',' * (described_class::DEFAULTS[:max_delimiters] + 1)}" }

        it 'skips the delimiter check (other defaults still apply)' do
          expect { validate }.not_to raise_error
        end
      end

      context 'when :max_header_columns is disabled' do
        let(:options) { { max_header_columns: nil } }
        let(:raw_csv) { "#{'col,' * described_class::DEFAULTS[:max_header_columns]}col\n" }

        it 'skips the header-column check (other defaults still apply)' do
          expect { validate }.not_to raise_error
        end
      end

      context 'when :max_rows is disabled' do
        let(:options) { { max_rows: nil } }
        let(:raw_csv) { "a,b\n" * (described_class::DEFAULTS[:max_rows] + 1) }

        it 'skips the row check (other defaults still apply)' do
          expect { validate }.not_to raise_error
        end
      end
    end

    describe ':max_size' do
      let(:options) { { max_size: 16 } }

      context 'when within the limit' do
        let(:raw_csv) { 'a,b,c' }

        it 'does not raise' do
          expect { validate }.not_to raise_error
        end
      end

      context 'when at exactly the limit' do
        let(:raw_csv) { 'a' * 16 }

        it 'does not raise' do
          expect { validate }.not_to raise_error
        end
      end

      context 'when exceeded' do
        let(:raw_csv) { 'a' * 17 }

        it 'raises SizeLimitError' do
          expect { validate }.to raise_error(described_class::SizeLimitError)
        end
      end
    end

    describe ':max_delimiters' do
      let(:options) { { max_delimiters: 5 } }

      context 'when beyond the limit' do
        let(:raw_csv) { "a,b,c\n1,2,3\n" }

        it 'raises when count is above the limit' do
          expect { validate }.to raise_error(described_class::DelimiterLimitError)
        end
      end

      context 'when at exactly the limit' do
        let(:raw_csv) { "a,b,c\n1,2" }

        it 'does not raise' do
          expect { validate }.not_to raise_error
        end
      end

      context 'with custom delimiter_chars' do
        let(:options) { { max_delimiters: 1, delimiter_chars: '|' } }

        it 'counts only the configured characters' do
          expect { described_class.new(options).validate!("a|b|c") }
            .to raise_error(described_class::DelimiterLimitError)
          expect { described_class.new(options).validate!("a,b,c,d") }
            .not_to raise_error
        end
      end

      context 'with semicolon and tab as separators' do
        let(:options) { { max_delimiters: 2 } }
        let(:raw_csv) { "a;b\tc;d\te" }

        it 'counts them toward the default delimiter set' do
          expect { validate }.to raise_error(described_class::DelimiterLimitError)
        end
      end
    end

    describe ':max_rows' do
      let(:options) { { max_rows: 2 } }

      context 'when newline count is at the limit' do
        let(:raw_csv) { "a,b\n1,2\n" }

        it 'does not raise' do
          expect { validate }.not_to raise_error
        end
      end

      context 'when newline count exceeds the limit' do
        let(:raw_csv) { "a,b\n1,2\n3,4\n" }

        it 'raises RowLimitError' do
          expect { validate }.to raise_error(described_class::RowLimitError)
        end
      end

      context 'with Windows line endings (\r\n)' do
        let(:raw_csv) { "a,b\r\n1,2\r\n" }

        it 'counts each line once, not twice' do
          expect { validate }.not_to raise_error
        end
      end
    end

    describe ':max_header_columns' do
      let(:options) { { max_header_columns: 3 } }

      context 'when header has fewer columns than the limit' do
        let(:raw_csv) { "a,b\n1,2\n" }

        it 'does not raise' do
          expect { validate }.not_to raise_error
        end
      end

      context 'when header has at the limit (commas == limit means columns > limit)' do
        let(:raw_csv) { "a,b,c,d\n" }

        it 'raises HeaderColumnLimitError' do
          expect { validate }.to raise_error(described_class::HeaderColumnLimitError)
        end
      end

      context 'when only the header line exists (no body row)' do
        let(:raw_csv) { 'a,b,c,d,e' }

        it 'still rejects a too-wide header' do
          expect { validate }.to raise_error(described_class::HeaderColumnLimitError)
        end
      end

      context 'when body rows have many delimiters but header is small' do
        let(:raw_csv) { "a,b\n1,2,3,4,5,6,7,8,9\n" }

        it 'does not raise (body width is bounded by :max_delimiters, not this check)' do
          expect { validate }.not_to raise_error
        end
      end
    end

    describe 'check order' do
      let(:options) { { max_size: 5, max_delimiters: 100, max_header_columns: 100 } }
      let(:raw_csv) { "a,b,c,d,e,f,g" }

      it 'raises size violations first' do
        expect { validate }.to raise_error(described_class::SizeLimitError)
      end
    end
  end
end
