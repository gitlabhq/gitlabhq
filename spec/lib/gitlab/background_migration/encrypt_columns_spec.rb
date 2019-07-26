# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::EncryptColumns, :migration, schema: 20180910115836 do
  let(:model) { Gitlab::BackgroundMigration::Models::EncryptColumns::WebHook }
  let(:web_hooks) { table(:web_hooks) }

  let(:plaintext_attrs) do
    {
      'encrypted_token' => nil,
      'encrypted_url' => nil,
      'token' =>  'secret',
      'url' => 'http://example.com?access_token=secret'
    }
  end

  let(:encrypted_attrs) do
    {
      'encrypted_token' => be_present,
      'encrypted_url' => be_present,
      'token' => nil,
      'url' => nil
    }
  end

  describe '#perform' do
    it 'encrypts columns for the specified range' do
      hooks = web_hooks.create([plaintext_attrs] * 5).sort_by(&:id)

      # Encrypt all but the first and last rows
      subject.perform(model, [:token, :url], hooks[1].id, hooks[3].id)

      hooks = web_hooks.where(id: hooks.map(&:id)).order(:id)

      aggregate_failures do
        expect(hooks[0]).to have_attributes(plaintext_attrs)
        expect(hooks[1]).to have_attributes(encrypted_attrs)
        expect(hooks[2]).to have_attributes(encrypted_attrs)
        expect(hooks[3]).to have_attributes(encrypted_attrs)
        expect(hooks[4]).to have_attributes(plaintext_attrs)
      end
    end

    it 'acquires an exclusive lock for the update' do
      relation = double('relation', each: nil)

      expect(model).to receive(:where) { relation }
      expect(relation).to receive(:lock) { relation }

      subject.perform(model, [:token, :url], 1, 1)
    end

    it 'skips already-encrypted columns' do
      values = {
        'encrypted_token' => 'known encrypted token',
        'encrypted_url' => 'known encrypted url',
        'token' => 'token',
        'url' => 'url'
      }

      hook = web_hooks.create(values)

      subject.perform(model, [:token, :url], hook.id, hook.id)

      hook.reload

      expect(hook).to have_attributes(values)
    end

    it 'reloads the model column information' do
      expect(model).to receive(:reset_column_information).and_call_original
      expect(model).to receive(:define_attribute_methods).and_call_original

      subject.perform(model, [:token, :url], 1, 1)
    end

    it 'fails if a source column is not present' do
      columns = model.columns.reject { |c| c.name == 'url' }
      allow(model).to receive(:columns) { columns }

      expect do
        subject.perform(model, [:token, :url], 1, 1)
      end.to raise_error(/source column: url is missing/)
    end

    it 'fails if a destination column is not present' do
      columns = model.columns.reject { |c| c.name == 'encrypted_url' }
      allow(model).to receive(:columns) { columns }

      expect do
        subject.perform(model, [:token, :url], 1, 1)
      end.to raise_error(/destination column: encrypted_url is missing/)
    end
  end
end
