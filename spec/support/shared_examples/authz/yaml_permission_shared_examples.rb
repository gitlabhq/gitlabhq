# frozen_string_literal: true

# requires the following let variables
# 1. definition_name - name value from an existing YAML definition file (e.g. :create_issue)
# 2. definition - hash representing the definition loaded from YAML file
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
    let(:available_for_tokens) { true }

    subject(:instance) do
      described_class.new(definition.merge({ available_for_tokens: available_for_tokens }), 'definition.yml')
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

    describe '#available_for_tokens?' do
      subject { instance.available_for_tokens? }

      it { is_expected.to be(true) }

      context 'when available_for_tokens is not defined' do
        let(:available_for_tokens) { nil }

        it { is_expected.to be(false) }
      end
    end
  end
end
