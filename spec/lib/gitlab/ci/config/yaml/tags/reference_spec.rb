# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml::Tags::Reference, feature_category: :pipeline_composition do
  let(:config) do
    Gitlab::Ci::Config::Yaml::Loader.new(yaml).load.content
  end

  describe '.tag' do
    it 'implements the tag method' do
      expect(described_class.tag).to eq('!reference')
    end
  end

  describe '#resolve' do
    subject { Gitlab::Ci::Config::Yaml::Tags::Resolver.new(config).to_hash }

    context 'with circular references' do
      let(:yaml) do
        <<~YML
        a: !reference [b]
        b: !reference [a]
        YML
      end

      it 'raises CircularReferenceError' do
        expect { subject }.to raise_error Gitlab::Ci::Config::Yaml::Tags::TagError, '!reference ["b"] is part of a circular chain'
      end
    end

    context 'with nested circular references' do
      let(:yaml) do
        <<~YML
        a: !reference [b, c]
        b: { c: !reference [d, e, f] }
        d: { e: { f: !reference [a] } }
        YML
      end

      it 'raises CircularReferenceError' do
        expect { subject }.to raise_error Gitlab::Ci::Config::Yaml::Tags::TagError, '!reference ["b", "c"] is part of a circular chain'
      end
    end

    context 'with missing references' do
      let(:yaml) { 'a: !reference [b]' }

      it 'raises MissingReferenceError' do
        expect { subject }.to raise_error Gitlab::Ci::Config::Yaml::Tags::TagError, '!reference ["b"] could not be found'
      end
    end

    context 'with invalid references' do
      using RSpec::Parameterized::TableSyntax

      where(:yaml, :error_message) do
        'a: !reference'          | '!reference [] is not valid'
        'a: !reference str'      | '!reference "str" is not valid'
        'a: !reference 1'        | '!reference "1" is not valid'
        'a: !reference [1]'      | '!reference [1] is not valid'
        'a: !reference { b: c }' | '!reference {"b"=>"c"} is not valid'
      end

      with_them do
        it 'raises an error' do
          expect { subject }.to raise_error Gitlab::Ci::Config::Yaml::Tags::TagError, error_message
        end
      end
    end

    context 'when the references are valid but do not match the config' do
      let(:yaml) do
        <<~YML
        a: [1, 2]
        b: [3, 4]
        c: !reference [a, b]
        YML
      end

      it 'raises a MissingReferenceError' do
        expect { subject }.to raise_error(
          Gitlab::Ci::Config::Yaml::Tags::Reference::MissingReferenceError,
          '!reference ["a", "b"] could not be found'
        )
      end
    end

    context 'with arrays' do
      let(:yaml) do
        <<~YML
        a: { b: [1, 2] }
        c: { d: { e: [3, 4] } }
        f: { g: [ !reference [a, b], 5, !reference [c, d, e]] }
        YML
      end

      it { is_expected.to match(a_hash_including({ f: { g: [[1, 2], 5, [3, 4]] } })) }
    end

    context 'with hashes' do
      context 'when referencing an entire hash' do
        let(:yaml) do
          <<~YML
          a: { b: { c: 'c', d: 'd' } }
          e: { f: !reference [a, b] }
          YML
        end

        it { is_expected.to match(a_hash_including({ e: { f: { c: 'c', d: 'd' } } })) }
      end

      context 'when referencing only a hash value' do
        let(:yaml) do
          <<~YML
          a: { b: { c: 'c', d: 'd' } }
          e: {  f: { g: !reference [a, b, c], h: 'h' } }
          i: !reference [e, f]
          YML
        end

        it { is_expected.to match(a_hash_including({ i: { g: 'c', h: 'h' } })) }
      end

      context 'when referencing a value before its definition' do
        let(:yaml) do
          <<~YML
          a: { b: !reference [c, d] }
          g: { h: { i: 'i', j: 1 } }
          c: { d: { e: !reference [g, h, j], f: 'f' } }
          YML
        end

        it { is_expected.to match(a_hash_including({ a: { b: { e: 1, f: 'f' } } })) }
      end
    end
  end
end
