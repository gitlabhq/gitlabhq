# frozen_string_literal: true

require 'spec_helper'

describe DeclarativePolicy do
  describe '.class_for' do
    it 'uses declarative_policy_class if present' do
      instance = Gitlab::ErrorTracking::ErrorEvent.new

      expect(described_class.class_for(instance)).to eq(ErrorTracking::BasePolicy)
    end

    it 'infers policy class from name' do
      instance = PersonalSnippet.new

      expect(described_class.class_for(instance)).to eq(PersonalSnippetPolicy)
    end

    it 'raises error if not found' do
      instance = Object.new

      expect { described_class.class_for(instance) }.to raise_error('no policy for Object')
    end

    context 'when found policy class does not inherit base' do
      before do
        stub_const('Foo', Class.new)
        stub_const('FooPolicy', Class.new)
      end

      it 'raises error if inferred class does not inherit Base' do
        instance = Foo.new

        expect { described_class.class_for(instance) }.to raise_error('no policy for Foo')
      end
    end
  end
end
