# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Maskable, feature_category: :ci_variables do
  let(:variable) { build(:ci_variable) }

  describe 'masked value validations' do
    subject { variable }

    context 'when variable is masked and expanded' do
      before do
        subject.masked = true
        subject.raw = false
      end

      it { is_expected.not_to allow_value('hello').for(:value) }
      it { is_expected.not_to allow_value('hello world').for(:value) }
      it { is_expected.not_to allow_value('hello$VARIABLEworld').for(:value) }
      it { is_expected.not_to allow_value('hello\rworld').for(:value) }
      it { is_expected.to allow_value('helloworld').for(:value) }
    end

    context 'when method :raw is not defined' do
      let(:test_var_class) do
        Struct.new(:masked?) do
          include ActiveModel::Validations
          include Ci::Maskable
        end
      end

      let(:variable) { test_var_class.new(true) }

      it 'evaluates masked variables as expanded' do
        expect(subject).not_to be_masked_and_raw
        expect(subject).to be_masked_and_expanded
      end
    end

    context 'when variable is masked and raw' do
      before do
        subject.masked = true
        subject.raw = true
      end

      it { is_expected.not_to allow_value('hello').for(:value) }
      it { is_expected.not_to allow_value('hello world').for(:value) }
      it { is_expected.to allow_value('hello\rworld').for(:value) }
      it { is_expected.to allow_value('hello$VARIABLEworld').for(:value) }
      it { is_expected.to allow_value('helloworld!!!').for(:value) }
      it { is_expected.to allow_value('hell******world').for(:value) }
      it { is_expected.to allow_value('helloworld123').for(:value) }
    end

    context 'when variable is not masked' do
      before do
        subject.masked = false
      end

      it { is_expected.to allow_value('hello').for(:value) }
      it { is_expected.to allow_value('hello world').for(:value) }
      it { is_expected.to allow_value('hello$VARIABLEworld').for(:value) }
      it { is_expected.to allow_value('hello\rworld').for(:value) }
      it { is_expected.to allow_value('helloworld').for(:value) }
    end
  end

  describe 'Regexes' do
    context 'with MASK_AND_RAW_REGEX' do
      subject { Ci::Maskable::MASK_AND_RAW_REGEX }

      it 'does not match strings shorter than 8 letters' do
        expect(subject.match?('hello')).to eq(false)
      end

      it 'does not match strings with spaces' do
        expect(subject.match?('hello world')).to eq(false)
      end

      it 'does not match strings that span more than one line' do
        string = <<~EOS
          hello
          world
        EOS

        expect(subject.match?(string)).to eq(false)
      end

      it 'matches valid strings' do
        expect(subject.match?('hello$VARIABLEworld')).to eq(true)
        expect(subject.match?('Hello+World_123/@:-~.')).to eq(true)
        expect(subject.match?('hello\rworld')).to eq(true)
        expect(subject.match?('HelloWorld%#^')).to eq(true)
      end
    end

    context 'with REGEX' do
      subject { Ci::Maskable::REGEX }

      it 'does not match strings shorter than 8 letters' do
        expect(subject.match?('hello')).to eq(false)
      end

      it 'does not match strings with spaces' do
        expect(subject.match?('hello world')).to eq(false)
      end

      it 'does not match strings with shell variables' do
        expect(subject.match?('hello$VARIABLEworld')).to eq(false)
      end

      it 'does not match strings with escape characters' do
        expect(subject.match?('hello\rworld')).to eq(false)
      end

      it 'does not match strings that span more than one line' do
        string = <<~EOS
          hello
          world
        EOS

        expect(subject.match?(string)).to eq(false)
      end

      it 'does not match strings using unsupported characters' do
        expect(subject.match?('HelloWorld%#^')).to eq(false)
      end

      it 'matches valid strings' do
        expect(subject.match?('Hello+World_123/@:-~.')).to eq(true)
      end
    end
  end

  describe '#to_hash_variable' do
    subject { variable.to_hash_variable }

    it 'exposes the masked attribute' do
      expect(subject).to include(:masked)
    end
  end
end
