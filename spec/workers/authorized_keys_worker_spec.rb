# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedKeysWorker, feature_category: :source_code_management do
  let(:worker) { described_class.new }

  describe '#perform' do
    context 'authorized_keys is enabled' do
      before do
        stub_application_setting(authorized_keys_enabled: true)
      end

      describe '#add_key' do
        it 'delegates to Gitlab::AuthorizedKeys' do
          expect_next_instance_of(Gitlab::AuthorizedKeys) do |instance|
            expect(instance).to receive(:add_key).with('foo', 'bar')
          end

          worker.perform('add_key', 'foo', 'bar')
        end
      end

      describe '#remove_key' do
        it 'delegates to Gitlab::AuthorizedKeys' do
          expect_next_instance_of(Gitlab::AuthorizedKeys) do |instance|
            expect(instance).to receive(:remove_key).with('foo', 'bar')
          end

          worker.perform('remove_key', 'foo', 'bar')
        end
      end

      describe 'valid action but it is a symbol not a string' do
        it 'raises an error' do
          expect(Gitlab::AuthorizedKeys).not_to receive(:new)

          expect do
            worker.perform(:add_key, 'foo', 'bar')
          end.to raise_error('Unknown action: :add_key')
        end
      end

      describe 'all other commands' do
        it 'raises an error' do
          expect(Gitlab::AuthorizedKeys).not_to receive(:new)

          expect do
            worker.perform('foo', 'bar', 'baz')
          end.to raise_error('Unknown action: "foo"')
        end
      end
    end

    context 'authorized_keys is disabled' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does nothing' do
        expect(Gitlab::AuthorizedKeys).not_to receive(:new)

        worker.perform('add_key', 'foo', 'bar')
      end
    end
  end
end
