# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/entity_exposure_growth'

RSpec.describe RuboCop::Cop::API::EntityExposureGrowth, feature_category: :api do
  let(:allowlist) { {} }

  before do
    allow(described_class).to receive(:allowlist).and_return(allowlist)
  end

  shared_examples 'flags expose calls not in the allowlist' do
    context 'when a field is not in the allowlist' do
      let(:allowlist) { { file_path => %w[id name] } }

      it 'registers an offense only for the unlisted field' do
        expect_offense(<<~RUBY)
          expose :id, documentation: { type: 'Integer', example: 1 }
          expose :new_field, documentation: { type: 'String' }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add `expose` calls to high-impact entities. [...]
          expose :name, documentation: { type: 'String', example: 'test' }
        RUBY
      end
    end

    context 'when an expose call with a block is not in the allowlist' do
      let(:allowlist) { { file_path => %w[id] } }

      it 'registers an offense on the expose call' do
        expect_offense(<<~RUBY)
          expose :id, documentation: { type: 'Integer', example: 1 }
          expose :url, documentation: { type: 'String' } do |obj|
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add `expose` calls to high-impact entities. [...]
            obj.url
          end
        RUBY
      end
    end

    context 'when all fields are in the allowlist' do
      let(:allowlist) { { file_path => %w[id name state] } }

      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          expose :id, documentation: { type: 'Integer', example: 1 }
          expose :name, documentation: { type: 'String', example: 'test' }
          expose :state, documentation: { type: 'String', example: 'active' }
        RUBY
      end
    end

    context 'when a field is exposed multiple times with different aliases' do
      let(:allowlist) { { file_path => %w[id topic_names topic_names] } }

      it 'does not register an offense when count matches' do
        expect_no_offenses(<<~RUBY)
          expose :id, documentation: { type: 'Integer', example: 1 }
          expose :topic_names, as: :tag_list, documentation: { type: 'String', is_array: true }
          expose :topic_names, as: :topics, documentation: { type: 'String', is_array: true }
        RUBY
      end

      it 'registers an offense on all occurrences when count exceeds the allowlist' do
        expect_offense(<<~RUBY)
          expose :id, documentation: { type: 'Integer', example: 1 }
          expose :topic_names, as: :tag_list, documentation: { type: 'String', is_array: true }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add `expose` calls to high-impact entities. [...]
          expose :topic_names, as: :topics, documentation: { type: 'String', is_array: true }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add `expose` calls to high-impact entities. [...]
          expose :topic_names, as: :new_alias, documentation: { type: 'String', is_array: true }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not add `expose` calls to high-impact entities. [...]
        RUBY
      end
    end
  end

  %w[
    lib/api/entities/user_basic.rb
    lib/api/entities/ci/pipeline_basic.rb
    ee/lib/api/entities/scim_identity.rb
  ].each do |path|
    context "when in #{path}" do
      let(:file_path) { path }

      before do
        allow(cop).to receive(:file_path_for_node).and_return(file_path)
      end

      it_behaves_like 'flags expose calls not in the allowlist'
    end
  end

  context 'when in a non-protected entity file' do
    before do
      allow(cop).to receive(:file_path_for_node).and_return('lib/api/entities/some_other_entity.rb')
    end

    it 'does not register an offense regardless of fields' do
      expect_no_offenses(<<~RUBY)
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :unknown_field, documentation: { type: 'String' }
      RUBY
    end
  end

  context 'when in a non-entity API file' do
    before do
      allow(cop).to receive(:file_path_for_node).and_return('lib/api/projects.rb')
    end

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        expose :name, documentation: { type: 'String' }
      RUBY
    end
  end

  context 'when expose is called with a non-symbol first argument' do
    let(:file_path) { 'lib/api/entities/user_basic.rb' }
    let(:allowlist) { { file_path => %w[id] } }

    before do
      allow(cop).to receive(:file_path_for_node).and_return(file_path)
    end

    it 'does not register an offense for a string argument' do
      expect_no_offenses(<<~RUBY)
        expose "dynamic_field", documentation: { type: 'String' }
      RUBY
    end

    it 'does not register an offense for a method call argument' do
      expect_no_offenses(<<~RUBY)
        expose some_method, documentation: { type: 'String' }
      RUBY
    end

    it 'does not register an offense when expose has no arguments' do
      expect_no_offenses(<<~RUBY)
        expose
      RUBY
    end
  end

  describe '.external_dependency_checksum' do
    before do
      described_class.instance_variable_set(:@external_dependency_checksum, nil)
    end

    after do
      described_class.instance_variable_set(:@external_dependency_checksum, nil)
    end

    it 'returns a SHA256 hex digest of the allowlist file' do
      expect(described_class.external_dependency_checksum).to match(/\A[a-f0-9]{64}\z/)
    end

    it 'is memoized' do
      first_call = described_class.external_dependency_checksum
      second_call = described_class.external_dependency_checksum

      expect(first_call).to equal(second_call)
    end
  end

  describe '.allowlist' do
    before do
      allow(described_class).to receive(:allowlist).and_call_original
      described_class.instance_variable_set(:@allowlist, nil)
    end

    after do
      # Re-clear so other tests using the stubbed allowlist are unaffected
      described_class.instance_variable_set(:@allowlist, nil)
    end

    it 'loads and returns a hash from the YAML file' do
      result = described_class.allowlist

      expect(result).to be_a(Hash)
      expect(result.keys).to all(be_a(String))
      expect(result.values).to all(be_an(Array))
    end
  end

  describe '.allowlist_file_path' do
    let(:path) { described_class.allowlist_file_path }

    it 'returns a path to the baseline YAML config' do
      expect(path).to end_with('rubocop/cop/api/config/api_entity_exposure_baseline.yml')
      expect(File.exist?(path)).to be true
    end
  end

  describe '#external_dependency_checksum' do
    before do
      described_class.instance_variable_set(:@external_dependency_checksum, nil)
    end

    after do
      described_class.instance_variable_set(:@external_dependency_checksum, nil)
    end

    it 'delegates to the class method' do
      expect(cop.external_dependency_checksum).to eq(described_class.external_dependency_checksum)
    end
  end
end
