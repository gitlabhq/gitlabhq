# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/debug'

RSpec.describe Tooling::Debug, feature_category: :tooling do
  let(:some_class) do
    Class.new do
      include Tooling::Debug

      def print_hello_world
        print 'hello world'
      end

      def puts_hello_world
        puts 'hello world'
      end
    end
  end

  after do
    # Ensure that debug mode is default disabled at start of specs.
    described_class.debug = false
  end

  shared_context 'when debug is enabled' do
    before do
      described_class.debug = true
    end
  end

  shared_context 'when debug is disabled' do
    before do
      described_class.debug = false
    end
  end

  shared_examples 'writes to stdout' do |str|
    it 'writes to stdout' do
      expect { subject }.to output(str).to_stdout
    end
  end

  shared_examples 'does not write to stdout' do
    it 'does not write to stdout' do
      expect { subject }.not_to output.to_stdout
    end
  end

  describe '#print' do
    subject { some_class.new.print_hello_world }

    context 'when debug is enabled' do
      include_context 'when debug is enabled'
      include_examples 'writes to stdout', 'hello world'
    end

    context 'when debug is disabled' do
      include_context 'when debug is disabled'
      include_examples 'does not write to stdout'
    end
  end

  describe '#puts' do
    subject { some_class.new.puts_hello_world }

    context 'when debug is enabled' do
      include_context 'when debug is enabled'
      include_examples 'writes to stdout', "hello world\n"
    end

    context 'when debug is disabled' do
      include_context 'when debug is disabled'
      include_examples 'does not write to stdout'
    end
  end
end
