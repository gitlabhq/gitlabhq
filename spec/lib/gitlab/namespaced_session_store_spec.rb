# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::NamespacedSessionStore do
  let(:key) { :some_key }

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
