# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProviderOnSelfHostedModels, migration: :gitlab_main_cell_setting, feature_category: :"self-hosted_models", migration_version: 20260505015003 do
  let(:migration) { described_class.new }
  let(:self_hosted_models) { table(:ai_self_hosted_models) }

  describe '#up' do
    context 'when self-hosted model identifier starts with bedrock/' do
      let!(:model) do
        self_hosted_models.create!(
          name: 'Bedrock Model',
          model: 0,
          endpoint: 'https://example.com',
          provider: 0,
          identifier: 'bedrock/some-model'
        )
      end

      it 'sets provider to 1 (bedrock)' do
        migration.up

        expect(model.reload.provider).to eq(1)
      end
    end

    context 'when self-hosted model identifier starts with vertex_ai/' do
      let!(:model) do
        self_hosted_models.create!(
          name: 'Vertex Model',
          model: 0,
          endpoint: 'https://example.com',
          provider: 0,
          identifier: 'vertex_ai/some-model'
        )
      end

      it 'sets provider to 2 (vertex_ai)' do
        migration.up

        expect(model.reload.provider).to eq(2)
      end
    end

    context 'when self-hosted model identifier does not match bedrock or vertex_ai' do
      let!(:model) do
        self_hosted_models.create!(
          name: 'API Model',
          model: 0,
          endpoint: 'https://example.com',
          provider: 0,
          identifier: 'custom_openai/some-model'
        )
      end

      it 'does not change the provider' do
        migration.up

        expect(model.reload.provider).to eq(0)
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { migration.down }.not_to raise_error
    end
  end
end
