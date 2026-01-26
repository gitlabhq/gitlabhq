# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineVariableItem, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:pipeline) { create(:ci_pipeline) }
  let(:key) { 'TEST_VAR' }
  let(:value) { 'test_value' }
  let(:variable_type) { 'env_var' }
  let(:raw) { false }
  let(:attrs) { { key: key, value: value, variable_type: variable_type, raw: raw } }

  subject(:variable) { described_class.new(pipeline: pipeline, **attrs) }

  describe 'validations' do
    it { is_expected.to validate_length_of(:value).is_at_most(described_class::MAX_VALUE_LENGTH) }
    it { is_expected.to validate_inclusion_of(:variable_type).in_array(%w[env_var file]) }
    it { is_expected.to validate_inclusion_of(:raw).in_array([true, false]) }

    describe 'key' do
      it { is_expected.to validate_presence_of(:key) }
      it { is_expected.to validate_length_of(:key).is_at_most(described_class::MAX_KEY_LENGTH) }

      where(:key, :valid) do
        'var'      | true
        'test_var' | true
        'VAR_123'  | true
        'VAR 123'  | false
        'var-123'  | false
        'VAR@NAME' | false
        ''         | false
      end

      with_them do
        it 'validates key format' do
          expect(variable.valid?).to be(valid)
          expect(variable.errors[:key]).to include("can contain only letters, digits and '_'.") unless valid
        end
      end
    end
  end

  describe 'defaults' do
    let(:attrs) { {} }

    it { expect(variable.variable_type).to eq('env_var') }
    it { expect(variable.raw).to be(false) }
  end

  describe '#secret_value' do
    let(:attrs) { { key: key, secret_value: 'secret_value' } }

    it 'is an alias for value for both reading and writing' do
      expect(variable.secret_value).to eq(variable.value)
    end
  end

  describe '#raw?' do
    where(:raw) { [true, false] }

    with_them do
      it 'is equivalent to raw' do
        expect(variable.raw?).to eq(variable.raw)
      end
    end
  end

  describe '#key=' do
    where(:key) { [' MY_VAR', 'MY_VAR  ', ' MY_VAR '] }

    with_them do
      it 'strips whitespace from the input' do
        expect(variable.key).to eq('MY_VAR')
      end
    end
  end

  describe '#variable_type=' do
    where(:variable_type, :expected_variable_type, :valid) do
      'env_var' | 'env_var'  | true
      'file'    | 'file'     | true
      'invalid' | 'invalid'  | false
      :env_var  | 'env_var'  | true
      :file     | 'file'     | true
      :invalid  | 'invalid'  | false
      1         | 'env_var'  | true
      2         | 'file'     | true
      3         | nil        | false
      nil       | nil        | false
    end

    with_them do
      it 'handles string, symbol, integer, and nil values as expected' do
        expect(variable.variable_type).to eq(expected_variable_type)
        expect(variable.valid?).to be(valid)
      end
    end
  end

  describe '#id' do
    let(:expected_id) { Digest::SHA256.hexdigest("#{pipeline.id}/#{key}") }

    it 'generates a SHA256 hash based on pipeline id and key' do
      expect(variable.id).to eq(expected_id)
    end

    it 'supports a global ID' do
      expect(variable.to_global_id.to_s).to eq("gid://gitlab/#{described_class.name}/#{expected_id}")
    end
  end

  describe '#to_hash_variable' do
    it 'returns the expected hash' do
      expect(variable.to_hash_variable).to eq({ key: key, value: value, public: false, file: false, raw: false })
    end
  end

  describe '#file?' do
    context 'when variable_type is not file' do
      it { expect(variable.file?).to be(false) }
    end

    context 'when variable_type is file' do
      let(:variable_type) { 'file' }

      it { expect(variable.file?).to be(true) }
    end
  end

  describe '#hook_attrs' do
    it 'returns a hash with key and value only' do
      expect(variable.hook_attrs).to eq({ key: key, value: value })
    end
  end
end
