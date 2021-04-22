# frozen_string_literal: true

require 'fast_spec_helper'
require 'active_model'

RSpec.describe ::Gitlab::Graphql::Deprecation do
  let(:options) { {} }

  subject(:deprecation) { described_class.parse(options) }

  describe '.parse' do
    context 'with nil' do
      let(:options) { nil }

      it 'parses to nil' do
        expect(deprecation).to be_nil
      end
    end

    context 'with empty options' do
      let(:options) { {} }

      it 'parses to an empty deprecation' do
        expect(deprecation).to eq(described_class.new)
      end
    end

    context 'with defined options' do
      let(:options) { { reason: :renamed, milestone: '10.10' } }

      it 'assigns the properties' do
        expect(deprecation).to eq(described_class.new(reason: 'This was renamed', milestone: '10.10'))
      end
    end
  end

  describe 'validations' do
    let(:options) { { reason: :renamed, milestone: '10.10' } }

    it { is_expected.to be_valid }

    context 'when the milestone is absent' do
      before do
        options.delete(:milestone)
      end

      it { is_expected.not_to be_valid }
    end

    context 'when the milestone is not milestone-ish' do
      before do
        options[:milestone] = 'next year'
      end

      it { is_expected.not_to be_valid }
    end

    context 'when the milestone is not a string' do
      before do
        options[:milestone] = 10.01
      end

      it { is_expected.not_to be_valid }
    end

    context 'when the reason is absent' do
      before do
        options.delete(:reason)
      end

      it { is_expected.not_to be_valid }
    end

    context 'when the reason is not a known reason' do
      before do
        options[:reason] = :not_stylish_enough
      end

      it { is_expected.not_to be_valid }
    end

    context 'when the reason is a string' do
      before do
        options[:reason] = 'not stylish enough'
      end

      it { is_expected.to be_valid }
    end

    context 'when the reason is a string ending with a period' do
      before do
        options[:reason] = 'not stylish enough.'
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe '#deprecation_reason' do
    context 'when there is a replacement' do
      let(:options) { { reason: :renamed, milestone: '10.10', replacement: 'X.y' } }

      it 'renders as reason-replacement-milestone' do
        expect(deprecation.deprecation_reason).to eq('This was renamed. Please use `X.y`. Deprecated in 10.10.')
      end
    end

    context 'when there is no replacement' do
      let(:options) { { reason: :renamed, milestone: '10.10' } }

      it 'renders as reason-milestone' do
        expect(deprecation.deprecation_reason).to eq('This was renamed. Deprecated in 10.10.')
      end
    end

    describe 'processing of reason' do
      described_class::REASONS.each_key do |known_reason|
        context "when the reason is a known reason such as #{known_reason.inspect}" do
          let(:options) { { reason: known_reason } }

          it 'renders the reason_text correctly' do
            expect(deprecation.deprecation_reason).to start_with(described_class::REASONS[known_reason])
          end
        end
      end

      context 'when the reason is any other string' do
        let(:options) { { reason: 'unhelpful' } }

        it 'appends a period' do
          expect(deprecation.deprecation_reason).to start_with('unhelpful.')
        end
      end
    end
  end

  describe '#edit_description' do
    let(:options) { { reason: :renamed, milestone: '10.10' } }

    it 'appends milestone:reason with a leading space if there is a description' do
      desc = deprecation.edit_description('Some description.')

      expect(desc).to eq('Some description. Deprecated in 10.10: This was renamed.')
    end

    it 'returns nil if there is no description' do
      desc = deprecation.edit_description(nil)

      expect(desc).to be_nil
    end
  end

  describe '#original_description' do
    it 'records the description passed to it' do
      deprecation.edit_description('Some description.')

      expect(deprecation.original_description).to eq('Some description.')
    end
  end

  describe '#markdown' do
    context 'when there is a replacement' do
      let(:options) { { reason: :renamed, milestone: '10.10', replacement: 'X.y' } }

      context 'when the context is :inline' do
        it 'renders on one line' do
          expectation = '**Deprecated** in 10.10. This was renamed. Use: [`X.y`](#xy).'

          expect(deprecation.markdown).to eq(expectation)
          expect(deprecation.markdown(context: :inline)).to eq(expectation)
        end
      end

      context 'when the context is :block' do
        it 'renders a warning note' do
          expectation = <<~MD.chomp
            WARNING:
            **Deprecated** in 10.10.
            This was renamed.
            Use: [`X.y`](#xy).
          MD

          expect(deprecation.markdown(context: :block)).to eq(expectation)
        end
      end
    end

    context 'when there is no replacement' do
      let(:options) { { reason: 'Removed', milestone: '10.10' } }

      context 'when the context is :inline' do
        it 'renders on one line' do
          expectation = '**Deprecated** in 10.10. Removed.'

          expect(deprecation.markdown).to eq(expectation)
          expect(deprecation.markdown(context: :inline)).to eq(expectation)
        end
      end

      context 'when the context is :block' do
        it 'renders a warning note' do
          expectation = <<~MD.chomp
            WARNING:
            **Deprecated** in 10.10.
            Removed.
          MD

          expect(deprecation.markdown(context: :block)).to eq(expectation)
        end
      end
    end
  end
end
