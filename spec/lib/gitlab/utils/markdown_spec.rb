# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::Markdown, feature_category: :gitlab_docs do
  let(:klass) do
    Class.new do
      include Gitlab::Utils::Markdown
    end
  end

  subject(:object) { klass.new }

  describe '#string_to_anchor' do
    subject { object.string_to_anchor(string) }

    let(:string) { 'My Header' }

    it 'converts string to anchor' do
      is_expected.to eq 'my-header'
    end

    context 'when string has punctuation' do
      let(:string) { 'My, Header!' }

      it 'removes punctuation' do
        is_expected.to eq 'my-header'
      end
    end

    context 'when string starts and ends with spaces' do
      let(:string) { '   My Header   ' }

      it 'removes extra spaces' do
        is_expected.to eq 'my-header'
      end
    end

    context 'when string has multiple spaces and dashes in the middle' do
      let(:string) { 'My -   -  -   Header' }

      it 'removes consecutive dashes' do
        is_expected.to eq 'my-header'
      end
    end

    context 'when string contains only digits' do
      let(:string) { '123' }

      it 'adds anchor prefix' do
        is_expected.to eq 'anchor-123'
      end
    end

    context 'when string has a product suffix' do
      %w[PREMIUM ULTIMATE FREE].each do |tier|
        [' ALL', ' SELF', ' SAAS'].each do |modifier|
          ['', ' BETA', ' EXPERIMENT'].each do |status|
            context "#{tier}#{modifier}#{status}" do
              context 'with "*" around a product suffix' do
                let(:string) { "My Header **(#{tier}#{modifier}#{status})**" }

                it 'ignores a product suffix' do
                  is_expected.to eq 'my-header'
                end
              end
            end
          end
        end
      end
      %w[BETA EXPERIMENT].each do |status|
        context 'with "*" around a product suffix' do
          let(:string) { "My Header **(#{status})**" }

          it 'ignores a product suffix' do
            is_expected.to eq 'my-header'
          end
        end
      end
    end

    context 'when string is empty' do
      let(:string) { '' }

      it 'returns an empty string' do
        is_expected.to eq ''
      end
    end
  end
end
