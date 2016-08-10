require 'spec_helper'

describe Gitlab::SlashCommands::Dsl do
  before :all do
    DummyClass = Class.new do
      include Gitlab::SlashCommands::Dsl

      desc 'A command with no args'
      command :no_args, :none do
        "Hello World!"
      end

      desc 'A command returning a value'
      command :returning do
        return 42
      end

      params 'The first argument'
      command :one_arg, :once, :first do |arg1|
        arg1
      end

      desc 'A command with two args'
      params 'The first argument', 'The second argument'
      command :two_args do |arg1, arg2|
        [arg1, arg2]
      end

      command :wildcard do |*args|
        args
      end

      noop true
      command :cc do |*args|
        args
      end
    end
  end
  let(:dummy) { DummyClass.new }

  describe '.command_definitions' do
    it 'returns an array with commands definitions' do
      expected = [
        { name: :no_args, aliases: [:none], description: 'A command with no args', params: [], noop: false },
        { name: :returning, aliases: [], description: 'A command returning a value', params: [], noop: false },
        { name: :one_arg, aliases: [:once, :first], description: '', params: ['The first argument'], noop: false },
        { name: :two_args, aliases: [], description: 'A command with two args', params: ['The first argument', 'The second argument'], noop: false },
        { name: :wildcard, aliases: [], description: '', params: [], noop: false },
        { name: :cc, aliases: [], description: '', params: [], noop: true }
      ]

      expect(DummyClass.command_definitions).to eq expected
    end
  end

  describe '.command_names' do
    it 'returns an array with commands definitions' do
      expect(DummyClass.command_names).to eq [
        :no_args, :none, :returning, :one_arg,
        :once, :first, :two_args, :wildcard
      ]
    end
  end

  describe 'command with no args' do
    context 'called with no args' do
      it 'succeeds' do
        expect(dummy.__send__(:no_args)).to eq 'Hello World!'
      end
    end
  end

  describe 'command with an explicit return' do
    context 'called with no args' do
      it 'succeeds' do
        expect(dummy.__send__(:returning)).to eq 42
      end
    end
  end

  describe 'command with one arg' do
    context 'called with one arg' do
      it 'succeeds' do
        expect(dummy.__send__(:one_arg, 42)).to eq 42
      end
    end
  end

  describe 'command with two args' do
    context 'called with two args' do
      it 'succeeds' do
        expect(dummy.__send__(:two_args, 42, 'foo')).to eq [42, 'foo']
      end
    end
  end

  describe 'command with wildcard' do
    context 'called with no args' do
      it 'succeeds' do
        expect(dummy.__send__(:wildcard)).to eq []
      end
    end

    context 'called with one arg' do
      it 'succeeds' do
        expect(dummy.__send__(:wildcard, 42)).to eq [42]
      end
    end

    context 'called with two args' do
      it 'succeeds' do
        expect(dummy.__send__(:wildcard, 42, 'foo')).to eq [42, 'foo']
      end
    end
  end
end
