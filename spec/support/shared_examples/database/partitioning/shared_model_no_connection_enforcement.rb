# frozen_string_literal: true

RSpec.shared_examples 'shared model without connection enforcement' do
  it 'works when connection is not set' do
    expect do
      subject
    end.not_to raise_error
  end

  it 'works when connection is set' do
    shared_model.using_connection(connection) do
      expect do
        subject
      end.not_to raise_error
    end
  end
end
