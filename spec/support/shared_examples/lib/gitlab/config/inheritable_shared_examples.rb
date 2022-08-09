# frozen_string_literal: true

RSpec.shared_examples 'with inheritable CI config' do
  using RSpec::Parameterized::TableSyntax

  let(:ignored_inheritable_columns) { [] }

  it 'does prepend an Inheritable mixin' do
    expect(described_class).to include_module(Gitlab::Config::Entry::Inheritable)
  end

  it 'all inheritable entries are covered' do
    inheritable_entries = inheritable_class.nodes.keys
    entries = described_class.nodes.keys

    expect(entries + ignored_inheritable_columns).to include(
      *inheritable_entries)
  end

  it 'all entries do have inherit flag' do
    without_inherit_flag = described_class.nodes.map do |key, factory|
      key if factory.inherit.nil?
    end.compact

    expect(without_inherit_flag).to be_empty
  end

  context 'for non-inheritable entries' do
    where(:entry_key) do
      described_class.nodes.map do |key, factory|
        [key] unless factory.inherit
      end.compact
    end

    with_them do
      it 'inheritable_class does not define entry' do
        expect(inheritable_class.nodes).not_to include(entry_key)
      end
    end
  end

  context 'for inheritable entries' do
    where(:entry_key, :entry_class) do
      described_class.nodes.map do |key, factory|
        [key, factory.entry_class] if factory.inherit
      end.compact
    end

    with_them do
      let(:specified) { double('deps_specified', 'specified?' => true, value: 'specified') }
      let(:unspecified) { double('unspecified', 'specified?' => false) }
      let(:inheritable) { double(inheritable_key, '[]' => unspecified) }

      let(:deps) do
        if inheritable_key
          double('deps', "#{inheritable_key}_entry" => inheritable, '[]' => unspecified)
        else
          inheritable
        end
      end

      it 'inheritable_class does define entry' do
        expect(inheritable_class.nodes).to include(entry_key)
        expect(inheritable_class.nodes[entry_key].entry_class).to eq(entry_class)
      end

      context 'when is specified' do
        it 'does inherit value' do
          expect(inheritable).to receive('[]').with(entry_key).and_return(specified)

          entry.send(:inherit!, deps)

          expect(entry[entry_key]).to eq(specified)
        end

        context 'when entry is specified' do
          let(:entry_specified) do
            double('entry_specified', 'specified?' => true, value: 'specified', errors: [])
          end

          it 'does not inherit value' do
            entry.send(:entries)[entry_key] = entry_specified

            allow(inheritable).to receive('[]').with(entry_key).and_return(specified)

            expect do
              # we ignore exceptions as `#overwrite_entry`
              # can raise exception on duplicates

              entry.send(:inherit!, deps)
            rescue described_class::InheritError
              nil
            end.not_to change { entry[entry_key] }
          end
        end
      end

      context 'when inheritable does not specify' do
        it 'does not inherit value' do
          entry.send(:inherit!, deps)

          expect(entry[entry_key]).to be_a(
            Gitlab::Config::Entry::Undefined)
        end
      end
    end
  end
end
