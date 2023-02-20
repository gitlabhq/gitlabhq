# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SharedModel, feature_category: :database do
  describe 'using an external connection' do
    let!(:original_connection) { described_class.connection }
    let(:new_connection) { double('connection') }

    it 'overrides the connection for the duration of the block', :aggregate_failures do
      expect_original_connection_around do
        described_class.using_connection(new_connection) do
          expect(described_class.connection).to be(new_connection)
        end
      end
    end

    it 'does not affect connections in other threads', :aggregate_failures do
      expect_original_connection_around do
        described_class.using_connection(new_connection) do
          expect(described_class.connection).to be(new_connection)

          Thread.new do
            expect(described_class.connection).not_to be(new_connection)
          end.join
        end
      end
    end

    it 'raises an error if the connection does not include `:gitlab_shared` schema' do
      allow(Gitlab::Database)
        .to receive(:gitlab_schemas_for_connection)
        .with(new_connection)
        .and_return([:gitlab_main])

      expect_original_connection_around do
        expect do
          described_class.using_connection(new_connection) {}
        end.to raise_error(/Cannot set `SharedModel` to connection/)
      end
    end

    context 'when multiple connection overrides are nested', :aggregate_failures do
      let(:second_connection) { double('connection') }

      it 'allows the nesting with the same connection object' do
        expect_original_connection_around do
          described_class.using_connection(new_connection) do
            expect(described_class.connection).to be(new_connection)

            described_class.using_connection(new_connection) do
              expect(described_class.connection).to be(new_connection)
            end

            expect(described_class.connection).to be(new_connection)
          end
        end
      end

      it 'raises an error if the connection is changed' do
        expect_original_connection_around do
          described_class.using_connection(new_connection) do
            expect(described_class.connection).to be(new_connection)

            expect do
              described_class.using_connection(second_connection) {}
            end.to raise_error(/Cannot change connection for Gitlab::Database::SharedModel/)

            expect(described_class.connection).to be(new_connection)
          end
        end
      end
    end

    context 'when the block raises an error', :aggregate_failures do
      it 're-raises the error, removing the overridden connection' do
        expect_original_connection_around do
          expect do
            described_class.using_connection(new_connection) do
              expect(described_class.connection).to be(new_connection)

              raise 'here comes an error!'
            end
          end.to raise_error(RuntimeError, 'here comes an error!')
        end
      end
    end
  end

  describe '#connection_db_config' do
    let!(:original_connection) { shared_model_class.connection }
    let!(:original_connection_db_config) { shared_model_class.connection_db_config }
    let(:shared_model) { shared_model_class.new }
    let(:shared_model_class) do
      Class.new(described_class) do
        self.table_name = 'postgres_async_indexes'
      end
    end

    it 'returns the class connection_db_config' do
      expect(shared_model.connection_db_config).to eq(described_class.connection_db_config)
    end

    context 'when switching the class connection' do
      before do
        skip_if_multiple_databases_not_setup
      end

      let(:new_base_model) { Ci::ApplicationRecord }
      let(:new_connection) { new_base_model.connection }

      it 'returns the db_config of the used connection when using load balancing' do
        expect_original_connection_around do
          described_class.using_connection(new_connection) do
            expect(shared_model.connection_db_config).to eq(new_base_model.connection_db_config)
          end
        end

        # it restores the connection_db_config afterwards
        expect(shared_model.connection_db_config).to eq(original_connection_db_config)
      end
    end
  end

  def expect_original_connection_around
    # For safety, ensure our original connection is distinct from our double
    # This should be the case, but in case of something leaking we should verify
    expect(original_connection).not_to be(new_connection)
    expect(described_class.connection).to be(original_connection)

    yield

    expect(described_class.connection).to be(original_connection)
  end
end
