# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Ci::Config::External::File::Base do
  subject { described_class.new(location) }

  before do
    allow_any_instance_of(described_class)
      .to receive(:content).and_return('key: value')
  end

  describe '#valid?' do
    context 'when location is not a YAML file' do
      let(:location) { 'some/file.txt' }

      it { is_expected.not_to be_valid }
    end

    context 'when location has not a valid naming scheme' do
      let(:location) { 'some/file/.yml' }

      it { is_expected.not_to be_valid }
    end

    context 'when location is a valid .yml extension' do
      let(:location) { 'some/file/config.yml' }

      it { is_expected.to be_valid }
    end

    context 'when location is a valid .yaml extension' do
      let(:location) { 'some/file/config.yaml' }

      it { is_expected.to be_valid }
    end

    context 'when there are YAML syntax errors' do
      let(:location) { 'some/file/config.yml' }

      before do
        allow_any_instance_of(described_class)
          .to receive(:content).and_return('invalid_syntax')
      end

      it 'is not a valid file' do
        expect(subject).not_to be_valid
        expect(subject.error_message).to match /does not have valid YAML syntax/
      end
    end
  end
end
