# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Ci::Config::External::File::Base do
  let(:context) { described_class::Context.new(nil, 'HEAD', nil, Set.new) }

  let(:test_class) do
    Class.new(described_class) do
      def initialize(params, context = {})
        @location = params

        super
      end
    end
  end

  subject { test_class.new(location, context) }

  before do
    allow_any_instance_of(test_class)
      .to receive(:content).and_return('key: value')
  end

  describe '#matching?' do
    context 'when a location is present' do
      let(:location) { 'some-location' }

      it 'returns true' do
        expect(subject).to be_matching
      end
    end

    context 'with a location is missing' do
      let(:location) { nil }

      it 'returns false' do
        expect(subject).not_to be_matching
      end
    end
  end

  describe '#valid?' do
    context 'when location is not a string' do
      let(:location) { %w(some/file.txt other/file.txt) }

      it { is_expected.not_to be_valid }
    end

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
        allow_any_instance_of(test_class)
          .to receive(:content).and_return('invalid_syntax')
      end

      it 'is not a valid file' do
        expect(subject).not_to be_valid
        expect(subject.error_message).to match /does not have valid YAML syntax/
      end
    end
  end

  describe '#to_hash' do
    context 'with includes' do
      let(:location) { 'some/file/config.yml' }
      let(:content) { 'include: { template: Bash.gitlab-ci.yml }'}

      before do
        allow_any_instance_of(test_class)
          .to receive(:content).and_return(content)
      end

      it 'does expand hash to include the template' do
        expect(subject.to_hash).to include(:before_script)
      end
    end
  end
end
