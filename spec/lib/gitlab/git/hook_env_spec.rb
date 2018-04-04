require 'spec_helper'

describe Gitlab::Git::HookEnv do
  let(:gl_repository) { 'project-123' }

  describe ".set" do
    context 'with RequestStore.store disabled' do
      before do
        allow(RequestStore).to receive(:active?).and_return(false)
      end

      it 'does not store anything' do
        described_class.set(gl_repository, GIT_OBJECT_DIRECTORY_RELATIVE: 'foo')

        expect(described_class.all(gl_repository)).to be_empty
      end
    end

    context 'with RequestStore.store enabled' do
      before do
        allow(RequestStore).to receive(:active?).and_return(true)
      end

      it 'whitelist some `GIT_*` variables and stores them using RequestStore' do
        described_class.set(
          gl_repository,
          GIT_OBJECT_DIRECTORY_RELATIVE: 'foo',
          GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE: 'bar',
          GIT_EXEC_PATH: 'baz',
          PATH: '~/.bin:/bin')

        git_env = described_class.all(gl_repository)

        expect(git_env[:GIT_OBJECT_DIRECTORY_RELATIVE]).to eq('foo')
        expect(git_env[:GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE]).to eq('bar')
        expect(git_env[:GIT_EXEC_PATH]).to be_nil
        expect(git_env[:PATH]).to be_nil
        expect(git_env[:bar]).to be_nil
      end
    end
  end

  describe ".all" do
    context 'with RequestStore.store enabled' do
      before do
        allow(RequestStore).to receive(:active?).and_return(true)
        described_class.set(
          gl_repository,
          GIT_OBJECT_DIRECTORY_RELATIVE: 'foo',
          GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE: ['bar'])
      end

      it 'returns an env hash' do
        expect(described_class.all(gl_repository)).to eq({
          'GIT_OBJECT_DIRECTORY_RELATIVE' => 'foo',
          'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => ['bar']
        })
      end
    end
  end

  describe ".to_env_hash" do
    context 'with RequestStore.store enabled' do
      using RSpec::Parameterized::TableSyntax

      let(:key) { 'GIT_OBJECT_DIRECTORY_RELATIVE' }
      subject { described_class.to_env_hash(gl_repository) }

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
          described_class.set(gl_repository, key.to_sym => input)
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

  describe 'thread-safety' do
    context 'with RequestStore.store enabled' do
      before do
        allow(RequestStore).to receive(:active?).and_return(true)
        described_class.set(gl_repository, GIT_OBJECT_DIRECTORY_RELATIVE: 'foo')
      end

      it 'is thread-safe' do
        another_thread = Thread.new do
          described_class.set(gl_repository, GIT_OBJECT_DIRECTORY_RELATIVE: 'bar')

          Thread.stop
          described_class.all(gl_repository)[:GIT_OBJECT_DIRECTORY_RELATIVE]
        end

        # Ensure another_thread runs first
        sleep 0.1 until another_thread.stop?

        expect(described_class.all(gl_repository)[:GIT_OBJECT_DIRECTORY_RELATIVE]).to eq('foo')

        another_thread.run
        expect(another_thread.value).to eq('bar')
      end
    end
  end
end
