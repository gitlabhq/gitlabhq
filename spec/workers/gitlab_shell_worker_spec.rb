# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabShellWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
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

    describe 'all other commands' do
      it 'delegates them to Gitlab::Shell' do
        expect_next_instance_of(Gitlab::Shell) do |instance|
          expect(instance).to receive(:foo).with('bar', 'baz')
        end

        worker.perform('foo', 'bar', 'baz')
      end
    end
  end
end
