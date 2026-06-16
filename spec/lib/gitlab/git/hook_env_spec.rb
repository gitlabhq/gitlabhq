# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::HookEnv, feature_category: :source_code_management do
  let(:relative_path) { 'snapshot/relative-path.git' }
  let(:gl_repository) { 'project-123' }
  let(:manifest_sha) { '1234567890abcdef1234567890abcdef12345678' }

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

      it 'allowlists GIT_MVCC_MANIFEST and pushes it onto the application context', :aggregate_failures do
        expect(Gitlab::ApplicationContext).to receive(:push).with(mvcc_manifest: manifest_sha)

        described_class.set(gl_repository, relative_path, GIT_MVCC_MANIFEST: manifest_sha)

        expect(described_class.all(gl_repository)['GIT_MVCC_MANIFEST']).to eq(manifest_sha)
      end

      it 'does not push onto the application context when GIT_MVCC_MANIFEST is absent' do
        expect(Gitlab::ApplicationContext).not_to receive(:push).with(hash_including(:mvcc_manifest))

        described_class.set(gl_repository, relative_path, GIT_OBJECT_DIRECTORY_RELATIVE: 'foo')
      end

      it 'does not push a malformed GIT_MVCC_MANIFEST onto the application context' do
        expect(Gitlab::ApplicationContext).not_to receive(:push).with(hash_including(:mvcc_manifest))

        described_class.set(gl_repository, relative_path, GIT_MVCC_MANIFEST: 'not-a-valid-sha')
      end
    end
  end

  describe ".pin_mvcc_manifest" do
    it 'pushes a well-formed manifest onto the application context' do
      expect(Gitlab::ApplicationContext).to receive(:push).with(mvcc_manifest: manifest_sha)

      described_class.pin_mvcc_manifest(manifest_sha)
    end

    it 'logs and does not push a malformed manifest', :aggregate_failures do
      expect(Gitlab::AppJsonLogger).to receive(:warn).with(message: 'Ignoring malformed MVCC manifest pin')
      expect(Gitlab::ApplicationContext).not_to receive(:push).with(hash_including(:mvcc_manifest))

      described_class.pin_mvcc_manifest('not-a-valid-sha')
    end

    it 'does nothing when the manifest is blank', :aggregate_failures do
      expect(Gitlab::AppJsonLogger).not_to receive(:warn)
      expect(Gitlab::ApplicationContext).not_to receive(:push).with(hash_including(:mvcc_manifest))

      described_class.pin_mvcc_manifest(nil)
      described_class.pin_mvcc_manifest('')
    end
  end

  describe ".mvcc_manifest" do
    it 'returns the mvcc_manifest from the application context' do
      Gitlab::ApplicationContext.with_context(mvcc_manifest: manifest_sha) do
        expect(described_class.mvcc_manifest).to eq(manifest_sha)
      end
    end

    it 'returns nil when no mvcc_manifest is set' do
      expect(described_class.mvcc_manifest).to be_nil
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
