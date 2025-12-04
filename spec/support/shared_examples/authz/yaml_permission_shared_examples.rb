# frozen_string_literal: true

# requires the following let variables
# 1. definition_name - name value from an existing YAML definition file (e.g. :create_issue)
RSpec.shared_examples 'loadable yaml permission or permission group' do
  describe '.all' do
    it 'loads all definitions' do
      expect(described_class.all).to be_a(Hash)
      expect(described_class.all).not_to be_empty
    end

    context 'when config_path is not implemented' do
      let_it_be(:test_class) do
        Class.new do
          include Authz::Concerns::YamlPermission
        end
      end

      it 'raises NotImplementedError' do
        expect { test_class.all }.to raise_error(NotImplementedError, /must implement \.config_path/)
      end
    end
  end

  describe '.get' do
    it 'returns a definition by name' do
      definition = described_class.get(definition_name.to_sym)

      expect(definition).to be_a(described_class)
      expect(definition.name).to eq(definition_name.to_s)
    end

    it 'returns nil for non-existent definition' do
      expect(described_class.get(:non_existent_definition)).to be_nil
    end
  end

  describe '.defined?' do
    subject(:defined) { described_class.defined?(def_name) }

    context 'when the definition exists' do
      context 'when definition name is passed as a symbol' do
        let(:def_name) { definition_name.to_sym }

        it { is_expected.to be(true) }
      end

      context 'when the definition name is passed as a string' do
        let(:def_name) { definition_name.to_s }

        it { is_expected.to be(true) }
      end
    end

    context 'when the definition does not exist' do
      let(:def_name) { :non_existent_definition }

      it { is_expected.to be(false) }
    end
  end

  describe 'instance methods' do
    let(:source_file) { 'config/authz/permissions/permission/test.yml' }
    let(:name) { 'test_permission' }
    let(:action) { nil }
    let(:resource) { nil }
    let(:boundaries) { %w[project] }
    let(:definition) do
      {
        name: name,
        description: 'Test permission description',
        feature_category: 'feature_category',
        action: action,
        resource: resource,
        boundaries: boundaries
      }
    end

    subject(:instance) do
      described_class.new(definition, source_file)
    end

    describe '#name' do
      it 'returns the definition name' do
        expect(instance.name).to eq(definition[:name])
      end
    end

    describe '#description' do
      it 'returns the definition description' do
        expect(instance.description).to eq(definition[:description])
      end
    end

    describe '#action' do
      let(:name) { 'another_test_permission' }

      subject { instance.action }

      it { is_expected.to eq('another') }

      context 'when an action is defined' do
        let(:action) { 'another_test' }

        it 'is expected to use the defined action' do
          is_expected.to eq('another_test')
        end
      end

      context 'when a resource is defined' do
        let(:resource) { 'permission' }

        it 'is expected to infer the action based on the resource' do
          is_expected.to eq('another_test')
        end
      end

      context 'when an action and resource are defined' do
        let(:action) { 'another_test' }
        let(:resource) { 'test_permission' }

        it 'is expected use the defined action' do
          is_expected.to eq('another_test')
        end
      end
    end

    describe '#resource' do
      let(:name) { 'another_test_permission' }

      subject { instance.resource }

      it { is_expected.to eq('test_permission') }

      context 'when a resource is defined' do
        let(:resource) { 'permission' }

        it 'is expected to use the defined resource' do
          is_expected.to eq('permission')
        end
      end

      context 'when an action is defined' do
        let(:action) { 'another_test' }

        it 'is expected to infer the resource based on the action' do
          is_expected.to eq('permission')
        end
      end

      context 'when a resource and action are defined' do
        let(:action) { 'another_test' }
        let(:resource) { 'test_permission' }

        it 'is expected use the defined resource' do
          is_expected.to eq('test_permission')
        end
      end
    end

    describe '#feature_category' do
      specify do
        expect(instance.feature_category).to eq(definition[:feature_category])
      end
    end

    describe '#boundaries' do
      subject { instance.boundaries }

      it { is_expected.to eq(boundaries) }

      context 'when boundaries are not defined' do
        let(:boundaries) { nil }

        it { is_expected.to eq([]) }
      end
    end

    describe '#source_file' do
      specify do
        expect(instance.source_file).to eq(source_file)
      end
    end
  end
end
