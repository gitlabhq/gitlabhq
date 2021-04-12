# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ide::SchemasConfigService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:filename) { 'sample.yml' }
  let(:schema_content) { double(body: '{"title":"Sample schema"}') }

  describe '#execute' do
    before do
      project.add_developer(user)

      allow(Gitlab::HTTP).to receive(:get).with(anything) do
        schema_content
      end
    end

    subject { described_class.new(project, user, filename: filename).execute }

    context 'feature flag schema_linting is enabled', unless: Gitlab.ee? do
      before do
        stub_feature_flags(schema_linting: true)
      end

      context 'when no predefined schema exists for the given filename' do
        it 'returns an empty object' do
          is_expected.to include(
            status: :success,
            schema: {})
        end
      end

      context 'when a predefined schema exists for the given filename' do
        let(:filename) { '.gitlab-ci.yml' }

        it 'uses predefined schema matches' do
          expect(Gitlab::HTTP).to receive(:get).with('https://json.schemastore.org/gitlab-ci')
          expect(subject[:schema]['title']).to eq "Sample schema"
        end
      end
    end

    context 'feature flag schema_linting is disabled', unless: Gitlab.ee? do
      it 'returns an empty object' do
        is_expected.to include(
          status: :success,
          schema: {})
      end
    end
  end
end
