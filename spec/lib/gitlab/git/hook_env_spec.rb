# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::HookEnv do
  let(:relative_path) { 'snapshot/relative-path.git' }
  let(:gl_repository) { 'project-123' }

  describe ".set" do
    context 'with RequestStore disabled' do
      it 'does not store anything' do
        described_class.set(gl_repository, relative_path, GIT_OBJECT_DIRECTORY_RELATIVE: 'foo')

        expect(described_class.all(gl_repository)).to be_empty
        expect(described_class.get_relative_path).to be_nil
      end
    end

    context 'with RequestStore enabled', :request_store do
      it 'whitelist some `GIT_*` variables and stores them using RequestStore' do
        described_class.set(
          gl_repository,
          relative_path,
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

  context 'with RequestStore enabled', :request_store do
    before do
      described_class.set(
        gl_repository,
        relative_path,
        GIT_OBJECT_DIRECTORY_RELATIVE: 'foo',
        GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE: ['bar'])
    end

    describe ".all" do
      it 'returns an env hash' do
        expect(described_class.all(gl_repository)).to eq({
          'GIT_OBJECT_DIRECTORY_RELATIVE' => 'foo',
          'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => ['bar']
        })
      end
    end

    describe ".get_relative_path" do
      it 'returns the relative path' do
        expect(described_class.get_relative_path).to eq(relative_path)
      end
    end
  end

  describe ".to_env_hash" do
    context 'with RequestStore enabled', :request_store do
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
          described_class.set(gl_repository, relative_path, key.to_sym => input)
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
    context 'with RequestStore enabled', :request_store do
      let(:other_relative_path) { 'other_relative_path' }

      before do
        allow(RequestStore).to receive(:active?).and_return(true)
        described_class.set(gl_repository, relative_path, GIT_OBJECT_DIRECTORY_RELATIVE: 'foo')
      end

      it 'is thread-safe' do
        another_thread = Thread.new do
          described_class.set(gl_repository, other_relative_path, GIT_OBJECT_DIRECTORY_RELATIVE: 'bar')

          Thread.stop

          {
            relative_path: described_class.get_relative_path,
            GIT_OBJECT_DIRECTORY_RELATIVE: described_class.all(gl_repository)[:GIT_OBJECT_DIRECTORY_RELATIVE]
          }
        end

        # Ensure another_thread runs first
        sleep 0.1 until another_thread.stop?

        expect(described_class.get_relative_path).to eq(relative_path)
        expect(described_class.all(gl_repository)[:GIT_OBJECT_DIRECTORY_RELATIVE]).to eq('foo')

        another_thread.run
        expect(another_thread.value).to eq({
          relative_path: other_relative_path,
          GIT_OBJECT_DIRECTORY_RELATIVE: 'bar'
        })
      end
    end
  end
end
