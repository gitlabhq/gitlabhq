# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::NamespacedSessionStore do
  let(:key) { :some_key }
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
