# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SharedModel do
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
            end.to raise_error(/cannot nest connection overrides/)

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

    def expect_original_connection_around
      # For safety, ensure our original connection is distinct from our double
      # This should be the case, but in case of something leaking we should verify
      expect(original_connection).not_to be(new_connection)
      expect(described_class.connection).to be(original_connection)

      yield

      expect(described_class.connection).to be(original_connection)
    end
  end
end
