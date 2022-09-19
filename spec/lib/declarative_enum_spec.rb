# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe DeclarativeEnum do
  let(:enum_module) do
    Module.new do
      extend DeclarativeEnum

      key :my_enum
      name 'MyEnumName'

      description "Enum description"

      define do
        foo value: 0, description: 'description of foo'
        bar value: 1, description: 'description of bar'
      end
    end
  end

  let(:original_definition) do
    {
      foo: { description: 'description of foo', value: 0 },
      bar: { description: 'description of bar', value: 1 }
    }
  end

  describe '.key' do
    subject(:key) { enum_module.key(new_key) }

    context 'when the argument is set' do
      let(:new_key) { :new_enum_key }

      it 'changes the key' do
        expect { key }.to change { enum_module.key }.from(:my_enum).to(:new_enum_key)
      end
    end

    context 'when the argument is `nil`' do
      let(:new_key) { nil }

      it { is_expected.to eq(:my_enum) }
    end
  end

  describe '.name' do
    subject(:name) { enum_module.name(new_name) }

    context 'when the argument is set' do
      let(:new_name) { 'NewMyEnumName' }

      it 'changes the name' do
        expect { name }.to change { enum_module.name }.from('MyEnumName').to('NewMyEnumName')
      end
    end

    context 'when the argument is `nil`' do
      let(:new_name) { nil }

      it { is_expected.to eq('MyEnumName') }
    end
  end

  describe '.description' do
    subject(:description) { enum_module.description(new_description) }

    context 'when the argument is set' do
      let(:new_description) { 'New enum description' }

      it 'changes the description' do
        expect { description }.to change { enum_module.description }.from('Enum description').to('New enum description')
      end
    end

    context 'when the argument is `nil`' do
      let(:new_description) { nil }

      it { is_expected.to eq('Enum description') }
    end
  end

  describe '.define' do
    subject(:define) { enum_module.define(&block) }

    context 'when there is a block given' do
      context 'when the given block tries to register the same key' do
        let(:block) do
          proc do
            foo value: 2, description: 'description of foo'
          end
        end

        it 'raises a `KeyCollisionError`' do
          expect { define }.to raise_error(DeclarativeEnum::Builder::KeyCollisionError)
        end
      end

      context 'when the given block does not try to register the same key' do
        let(:expected_new_definition) { original_definition.merge(zoo: { description: 'description of zoo', value: 0 }) }
        let(:block) do
          proc do
            zoo value: 0, description: 'description of zoo'
          end
        end

        it 'appends the new definition' do
          expect { define }.to change { enum_module.definition }.from(original_definition).to(expected_new_definition)
        end
      end
    end

    context 'when there is no block given' do
      let(:block) { nil }

      it 'raises a LocalJumpError' do
        expect { define }.to raise_error(LocalJumpError)
      end
    end
  end

  describe '.definition' do
    subject { enum_module.definition }

    it { is_expected.to eq(original_definition) }
  end

  describe 'extending the enum module' do
    let(:extended_definition) { original_definition.merge(zoo: { value: 2, description: 'description of zoo' }) }
    let(:new_enum_module) do
      Module.new do
        extend DeclarativeEnum

        define do
          zoo value: 2, description: 'description of zoo'
        end
      end
    end

    subject(:prepend_new_enum_module) { enum_module.prepend(new_enum_module) }

    it 'extends the values of the base enum module' do
      expect { prepend_new_enum_module }.to change { enum_module.definition }.from(original_definition)
                                                                             .to(extended_definition)
    end
  end
end
