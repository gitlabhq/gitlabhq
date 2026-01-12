# frozen_string_literal: true

RSpec.shared_examples 'shared model without connection enforcement' do
  context 'when enforce_explicit_connection_for_partitioned_shared_models is enabled' do
    before do
      stub_feature_flags(enforce_explicit_connection_for_partitioned_shared_models: true)
    end

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

  context 'when enforce_explicit_connection_for_partitioned_shared_models is disabled' do
    before do
      stub_feature_flags(enforce_explicit_connection_for_partitioned_shared_models: false)
    end

    it 'works without explicit connection' do
      expect do
        subject
      end.not_to raise_error
    end
  end
end
