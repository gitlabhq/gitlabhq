# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml::Tags, feature_category: :pipeline_composition do
  using RSpec::Parameterized::TableSyntax

  describe '.find_unresolved_tag' do
    subject { described_class.find_unresolved_tag(value) }

    let(:tag) do
      Gitlab::Ci::Config::Yaml::Tags::Reference.new.tap do |reference|
        reference.data = { tag: '!reference', seq: %w[.shared] }
      end
    end

    where(:case_name, :value, :expected) do
      'a tag'                        | ref(:tag)                | ref(:tag)
      'a tag in an array'            | ['plain', ref(:tag)]     | ref(:tag)
      'a tag in an array of arrays'  | [['plain', ref(:tag)]]   | ref(:tag)
      'a tag in a hash value'        | { 'key' => ref(:tag) }   | ref(:tag)
      'a tag in a hash key'          | { ref(:tag) => 'plain' } | ref(:tag)
      'a tag in a hash in an array'  | [{ 'key' => ref(:tag) }] | ref(:tag)
      'a string'                     | 'plain'                  | nil
      'an array of scalars'          | ['plain', 1, true]       | nil
      'a hash of scalars'            | { 'key' => 'plain' }     | nil
      'nil'                          | nil                      | nil
      'an empty array'               | []                       | nil
    end

    with_them do
      it { is_expected.to be(expected) }
    end

    context 'with more than one tag' do
      let(:other_tag) do
        Gitlab::Ci::Config::Yaml::Tags::Reference.new.tap do |reference|
          reference.data = { tag: '!reference', seq: %w[.other] }
        end
      end

      it 'returns the first one' do
        expect(described_class.find_unresolved_tag([tag, other_tag])).to be(tag)
      end
    end
  end
end
