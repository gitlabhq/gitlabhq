# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::NamespacedSessionStore do
  let(:key) { :some_key }

  context 'current session' do
    subject { described_class.new(key) }

    it 'stores data under the specified key' do
      Gitlab::Session.with_session({}) do
        subject[:new_data] = 123

        expect(Thread.current[:session_storage][key]).to eq(new_data: 123)
      end
    end

    it 'retrieves data from the given key' do
      Thread.current[:session_storage] = { key => { existing_data: 123 } }

      expect(subject[:existing_data]).to eq 123
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
