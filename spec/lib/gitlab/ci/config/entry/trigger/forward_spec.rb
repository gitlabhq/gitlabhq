# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Trigger::Forward do
  subject(:entry) { described_class.new(config) }

  context 'when entry config is correct' do
    let(:config) do
      {
        yaml_variables: false,
        pipeline_variables: false
      }
    end

    it 'returns set values' do
      expect(entry.value).to eq(yaml_variables: false, pipeline_variables: false)
    end

    it { is_expected.to be_valid }
  end

  context 'when entry config value is empty' do
    let(:config) do
      {}
    end

    it 'returns empty' do
      expect(entry.value).to eq({})
    end

    it { is_expected.to be_valid }
  end

  context 'when entry value is not correct' do
    context 'invalid attribute' do
      let(:config) do
        {
          xxx_variables: true
        }
      end

      it { is_expected.not_to be_valid }

      it 'reports error' do
        expect(entry.errors).to include 'forward config contains unknown keys: xxx_variables'
      end
    end

    context 'non-boolean value' do
      let(:config) do
        {
          yaml_variables: 'okay'
        }
      end

      it { is_expected.not_to be_valid }

      it 'reports error' do
        expect(entry.errors).to include 'forward yaml variables should be a boolean value'
      end
    end
  end
end
