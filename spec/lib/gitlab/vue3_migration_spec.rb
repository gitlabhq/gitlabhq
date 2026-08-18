# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Vue3Migration, feature_category: :tooling do
  let(:user) { build_stubbed(:user) }

  # The `feature_flag` value used by stubbed migration definitions in these
  # tests. This string never has to match a real flag in `config/feature_flags`:
  # we mock `Feature.enabled?` directly so the resolver's behavior can be
  # verified independently of any specific flag's lifecycle.
  let(:fake_flag) { 'a_flag_name' }

  shared_context 'with stubbed Vue 3 migration definitions' do
    before do
      described_class.clear_memoization!
      allow(described_class).to receive(:definitions).and_return(definitions)
    end

    after do
      described_class.clear_memoization!
    end
  end

  describe '.entrypoint_for' do
    include_context 'with stubbed Vue 3 migration definitions'

    subject(:resolved) { described_class.entrypoint_for(name, current_user: user) }

    context 'when the entry has no rollout record' do
      let(:definitions) { {} }
      let(:name) { 'pages.unknown' }

      it 'returns the original name unchanged' do
        expect(resolved).to eq('pages.unknown')
      end
    end

    context 'when the entry is rolling out' do
      let(:definitions) { { 'pages.foo' => fake_flag } }
      let(:name) { 'pages.foo' }

      context 'and the feature flag is enabled' do
        before do
          allow(Feature).to receive(:enabled?).with(fake_flag.to_sym, user).and_return(true)
        end

        it 'returns the .vue3 variant' do
          expect(resolved).to eq('pages.foo.vue3')
        end
      end

      context 'and the feature flag is disabled' do
        before do
          allow(Feature).to receive(:enabled?).with(fake_flag.to_sym, user).and_return(false)
        end

        it 'returns the original name' do
          expect(resolved).to eq('pages.foo')
        end
      end

      context 'and the feature flag is enabled only for a specific user' do
        let(:other_user) { build_stubbed(:user) }

        before do
          allow(Feature).to receive(:enabled?).with(fake_flag.to_sym, user).and_return(true)
          allow(Feature).to receive(:enabled?).with(fake_flag.to_sym, other_user).and_return(false)
        end

        it 'returns the .vue3 variant for the targeted user' do
          expect(described_class.entrypoint_for('pages.foo', current_user: user)).to eq('pages.foo.vue3')
        end

        it 'returns the original name for other users' do
          expect(described_class.entrypoint_for('pages.foo', current_user: other_user)).to eq('pages.foo')
        end
      end
    end
  end

  describe '.definitions' do
    before do
      described_class.clear_memoization!
    end

    after do
      described_class.clear_memoization!
    end

    context 'in development and test (integration with the on-disk YAML files)' do
      it 'maps rollout entry names to their feature flag' do
        result = described_class.definitions

        expect(result).to be_a(Hash)
        expect(result).not_to be_empty
        expect(result.keys).to all(start_with('pages.'))
        expect(result.values).to all(be_a(String))
      end

      it 'excludes migrated entries' do
        migrated_docs = Dir.glob(Rails.root.join(described_class::VUE3_MIGRATION_GLOB)).filter_map do |file|
          doc = YAML.safe_load_file(file)
          file if doc['status'] == described_class::VUE3_MIGRATION_STATUS_MIGRATED
        end

        migrated_docs.each do |file|
          entry_name = described_class.send(:entry_name_from_file, file)
          expect(described_class.definitions).not_to have_key(entry_name)
        end
      end
    end

    context 'in production' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
      end

      context 'when the compiled manifest is readable' do
        before do
          allow(Gitlab::Webpack::FileLoader).to receive(:load)
            .with(described_class::VUE3_MIGRATION_MANIFEST_FILENAME)
            .and_return('{"pages.foo":{"feature_flag":"a_flag_name"}}')
        end

        it 'loads definitions from the manifest' do
          expect(described_class.definitions).to eq('pages.foo' => fake_flag)
        end

        it 'resolves entrypoints end-to-end' do
          allow(Feature).to receive(:enabled?).with(fake_flag.to_sym, user).and_return(true)

          expect(described_class.entrypoint_for('pages.foo', current_user: user)).to eq('pages.foo.vue3')
        end
      end

      context 'when the compiled manifest cannot be read' do
        before do
          original_error = Errno::ENOENT.new('vue3_migration.json')
          allow(Gitlab::Webpack::FileLoader).to receive(:load)
            .with(described_class::VUE3_MIGRATION_MANIFEST_FILENAME)
            .and_raise(Gitlab::Webpack::FileLoader::StaticLoadError.new('some/path', original_error))
        end

        it 'raises a descriptive error instead of silently serving Vue 2' do
          expect { described_class.definitions }.to raise_error(
            described_class::ManifestLoadError,
            /Could not load compiled vue3_migration\.json.*rake gitlab:assets:compile/m
          )
        end
      end
    end
  end
end
