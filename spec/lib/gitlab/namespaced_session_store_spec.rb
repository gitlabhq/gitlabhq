# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::NamespacedSessionStore do
  let(:key) { :some_key }

  describe 'Enumerable methods' do
    subject(:instance) { described_class.new(key) }

    context 'with data in the session' do
      around do |ex|
        Gitlab::Session.with_session(key => { a: 1, b: 2 }) { ex.run }
      end

      it 'passes .each call to storage hash' do
        keys = []
        values = []
        instance.each do |key, val|
          keys << key
          values << val
        end
        expect(keys).to match_array([:a, :b])
        expect(values).to match_array([1, 2])
      end

      it 'passes .map to storage hash' do
        expect(instance.map { |item| item }).to match_array([[:a, 1], [:b, 2]])
      end

      it 'converts into a basic hash upon request' do
        expect(instance.to_h).to match(a: 1, b: 2)
      end
    end

    context 'with no data in session' do
      subject(:iterator) do
        instance.each do # rubocop:disable Lint/UnreachableLoop -- no clearer way to write this
          raise 'This code should not be reachable'
        end
      end

      around do |ex|
        Gitlab::Session.with_session(another_key: { a: 1, b: 2 }) { ex.run }
      end

      it 'does not iterate when session is not initialized' do
        expect { iterator }.not_to raise_error
      end

      it 'converts to empty hash with .to_h' do
        expect(instance.to_h).to eq({})
      end
    end

    context 'with empty data in session' do
      subject(:iterator) do
        instance.each do # rubocop:disable Lint/UnreachableLoop -- no clearer way to write this
          raise 'This code should not be reachable'
        end
      end

      around do |ex|
        Gitlab::Session.with_session(key => {}) { ex.run }
      end

      it 'does not raise error' do
        expect { iterator }.not_to raise_error
      end

      it 'converts to empty hash with .to_h' do
        expect(instance.to_h).to eq({})
      end
    end
  end

  context 'current session' do
    subject { described_class.new(key) }

    it 'retrieves data from the given key' do
      Thread.current[:session_storage] = { key => { existing_data: 123 } }

      expect(subject[:existing_data]).to eq 123
    end

    context 'when namespace key does not exist' do
      before do
        Thread.current[:session_storage] = {}
      end

      it 'does not create namespace key when reading a value' do
        expect(subject[:non_existent_key]).to eq(nil)
        expect(Thread.current[:session_storage]).to eq({})
      end

      it 'stores data under the specified key' do
        subject[:new_data] = 123

        expect(Thread.current[:session_storage][key]).to eq(new_data: 123)
      end
    end
  end

  context 'passed in session' do
    let(:data) { { 'data' => 42 } }
    let(:session) { { 'some_key' => data } }

    subject { described_class.new(key, session.with_indifferent_access) }

    it 'retrieves data from the given key' do
      expect(subject['data']).to eq 42
    end
  end
end
