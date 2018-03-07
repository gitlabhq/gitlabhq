require 'spec_helper'

describe Gitlab::Git::Env do
  describe ".set" do
    context 'with RequestStore.store disabled' do
      before do
        allow(RequestStore).to receive(:active?).and_return(false)
      end

      it 'does not store anything' do
        described_class.set(GIT_OBJECT_DIRECTORY: 'foo')

        expect(described_class.all).to be_empty
      end
    end

    context 'with RequestStore.store enabled' do
      before do
        allow(RequestStore).to receive(:active?).and_return(true)
      end

      it 'whitelist some `GIT_*` variables and stores them using RequestStore' do
        described_class.set(
          GIT_OBJECT_DIRECTORY: 'foo',
          GIT_ALTERNATE_OBJECT_DIRECTORIES: 'bar',
          GIT_EXEC_PATH: 'baz',
          PATH: '~/.bin:/bin')

        expect(described_class[:GIT_OBJECT_DIRECTORY]).to eq('foo')
        expect(described_class[:GIT_ALTERNATE_OBJECT_DIRECTORIES]).to eq('bar')
        expect(described_class[:GIT_EXEC_PATH]).to be_nil
        expect(described_class[:bar]).to be_nil
      end
    end
  end

  describe ".all" do
    context 'with RequestStore.store enabled' do
      before do
        allow(RequestStore).to receive(:active?).and_return(true)
        described_class.set(
          GIT_OBJECT_DIRECTORY: 'foo',
          GIT_ALTERNATE_OBJECT_DIRECTORIES: ['bar'])
      end

      it 'returns an env hash' do
        expect(described_class.all).to eq({
          'GIT_OBJECT_DIRECTORY' => 'foo',
          'GIT_ALTERNATE_OBJECT_DIRECTORIES' => ['bar']
        })
      end
    end
  end

  describe ".to_env_hash" do
    context 'with RequestStore.store enabled' do
      using RSpec::Parameterized::TableSyntax

      let(:key) { 'GIT_OBJECT_DIRECTORY' }
      subject { described_class.to_env_hash }

      where(:input, :output) do
        nil         | nil
        'foo'       | 'foo'
        []          | ''
        ['foo']     | 'foo'
        %w[foo bar] | 'foo:bar'
      end

      with_them do
        before do
          allow(RequestStore).to receive(:active?).and_return(true)
          described_class.set(key.to_sym => input)
        end

        it 'puts the right value in the hash' do
          if output
            expect(subject.fetch(key)).to eq(output)
          else
            expect(subject.has_key?(key)).to eq(false)
          end
        end
      end
    end
  end

  describe ".[]" do
    context 'with RequestStore.store enabled' do
      before do
        allow(RequestStore).to receive(:active?).and_return(true)
      end

      before do
        described_class.set(
          GIT_OBJECT_DIRECTORY: 'foo',
          GIT_ALTERNATE_OBJECT_DIRECTORIES: 'bar')
      end

      it 'returns a stored value for an existing key' do
        expect(described_class[:GIT_OBJECT_DIRECTORY]).to eq('foo')
      end

      it 'returns nil for an non-existing key' do
        expect(described_class[:foo]).to be_nil
      end
    end
  end

  describe 'thread-safety' do
    context 'with RequestStore.store enabled' do
      before do
        allow(RequestStore).to receive(:active?).and_return(true)
        described_class.set(GIT_OBJECT_DIRECTORY: 'foo')
      end

      it 'is thread-safe' do
        another_thread = Thread.new do
          described_class.set(GIT_OBJECT_DIRECTORY: 'bar')

          Thread.stop
          described_class[:GIT_OBJECT_DIRECTORY]
        end

        # Ensure another_thread runs first
        sleep 0.1 until another_thread.stop?

        expect(described_class[:GIT_OBJECT_DIRECTORY]).to eq('foo')

        another_thread.run
        expect(another_thread.value).to eq('bar')
      end
    end
  end
end
