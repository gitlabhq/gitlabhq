# frozen_string_literal: true

RSpec.shared_examples 'shared model connection enforcement' do
  it 'raises error when connection is not set' do
    error_message = 'Connection not set for SharedModel partition strategy. ' \
      'Use SharedModel.using_connection() to set the correct connection. ' \
      'Using the default database is dangerous.'
    expect do
      subject
    end.to raise_error(error_message)
  end

  it 'works when connection is set' do
    shared_model.using_connection(connection) do
      expect do
        subject
      end.not_to raise_error
    end
  end
end
