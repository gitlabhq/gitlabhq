# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Maskable do
  let(:variable) { build(:ci_variable) }

  describe 'masked value validations' do
    subject { variable }

    context 'when variable is masked' do
      before do
        subject.masked = true
      end

      it { is_expected.not_to allow_value('hello').for(:value) }
      it { is_expected.not_to allow_value('hello world').for(:value) }
      it { is_expected.not_to allow_value('hello$VARIABLEworld').for(:value) }
      it { is_expected.not_to allow_value('hello\rworld').for(:value) }
      it { is_expected.to allow_value('helloworld').for(:value) }
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

  describe 'REGEX' do
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

  describe '#to_runner_variable' do
    subject { variable.to_runner_variable }

    it 'exposes the masked attribute' do
      expect(subject).to include(:masked)
    end
  end
end
