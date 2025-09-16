# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Build::Cache, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:head_sha) { project.repository.head_commit.id }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: head_sha) }

  let(:cache_index) { 1 }
  let(:processor) { described_class.new(pipeline, config, cache_index) }

  describe '#attributes' do
    subject { processor.attributes }

    context 'with cache:key' do
      let(:config) do
        {
          key: 'a-key',
          paths: ['vendor/ruby']
        }
      end

      it { is_expected.to include(config) }
    end

    context 'with cache:key as a symbol' do
      let(:config) do
        {
          key: :a_key,
          paths: ['vendor/ruby']
        }
      end

      it { is_expected.to include(config.merge(key: 'a_key')) }
    end

    context 'with cache:key:files' do
      let_it_be(:content_hash) { '9a0a563ac940f27f1599e2e1417d18f90bac7bce' }
      let_it_be(:directory_hash) { '74bf43fb1090f161bdd4e265802775dbda2f03d1' }

      context 'with existing files' do
        let(:config) do
          {
            key: { files: ['VERSION', 'Gemfile.zip'] },
            paths: ['vendor/ruby']
          }
        end

        it 'builds cache key from file content hashes' do
          expect(subject[:key]).to match(/^1-[a-f0-9]+$/)
          expect(subject[:paths]).to eq(['vendor/ruby'])
        end
      end

      context 'with files starting with ./' do
        let(:config) do
          {
            key: { files: ['Gemfile.zip', './VERSION'] },
            paths: ['vendor/ruby']
          }
        end

        it 'builds cache key from file content hashes' do
          expect(subject[:key]).to match(/^1-[a-f0-9]+$/)
          expect(subject[:paths]).to eq(['vendor/ruby'])
        end
      end

      context 'with invalid file patterns' do
        where(:files, :expected_prefix) do
          [
            [[], '1'],
            [['Gemfile.zip/'], '1_Gemfile'],
            [['Gemfile.zip\nVERSION'], '1_Gemfile'],
            [['project-gemfile.lock', ''], '1_project-gemfile_']
          ]
        end

        with_them do
          let(:config) { { key: { files: files } } }

          it 'falls back to default key' do
            expect(subject[:key]).to match(/^1-(?:default|[a-f0-9]+)$/)
          end
        end
      end

      context 'with directories' do
        where(:directory_pattern, :expected_prefix) do
          [
            [['foo/bar'], '1_foo/bar'],
            [['foo/bar/'], '1_foo/bar/'],
            [['foo/bar/*'], '1_foo/bar/*']
          ]
        end

        with_them do
          let(:config) { { key: { files: directory_pattern } } }

          it 'builds cache key from directory commit hash' do
            expect(subject[:key]).to match(/^1-(?:default|[a-f0-9]+)$/)
          end
        end
      end
    end

    context 'with cache:key:prefix' do
      context 'without files' do
        let(:config) do
          {
            key: {
              prefix: 'a-prefix'
            },
            paths: ['vendor/ruby']
          }
        end

        it 'adds prefix to default key' do
          expected = {
            key: 'a-prefix-default',
            paths: ['vendor/ruby']
          }

          is_expected.to include(expected)
        end
      end

      context 'with existing files' do
        let(:config) do
          {
            key: {
              files: ['VERSION', 'Gemfile.zip'],
              prefix: 'a-prefix'
            },
            paths: ['vendor/ruby']
          }
        end

        it 'adds prefix key' do
          expect(subject[:key]).to match(/^a-prefix-[a-f0-9]+$/)
          expect(subject[:paths]).to eq(['vendor/ruby'])
        end
      end

      context 'with missing files' do
        let(:config) do
          {
            key: {
              files: ['project-gemfile.lock', ''],
              prefix: 'a-prefix'
            },
            paths: ['vendor/ruby']
          }
        end

        it 'adds prefix to default key' do
          expected = {
            key: 'a-prefix-default',
            paths: ['vendor/ruby']
          }

          is_expected.to include(expected)
        end
      end
    end

    context 'with cache:key:files_commits' do
      let_it_be(:files_hash) { '703ecc8fef1635427a1f86a8a1a308831c122392' }

      context 'with existing files' do
        let(:config) { { key: { files_commits: ['VERSION', 'Gemfile.zip'] } } }

        it 'builds cache key from file commit hash' do
          expect(subject[:key]).to match(/^1-[a-f0-9]+$/)
        end
      end

      context 'with custom prefix' do
        let(:config) do
          {
            key: { files_commits: ['VERSION', 'Gemfile.zip'], prefix: 'a-prefix' },
            paths: ['vendor/ruby']
          }
        end

        it 'uses custom prefx along with commit hash' do
          expect(subject[:key]).to match(/^a-prefix-[a-f0-9]+$/)
          expect(subject[:paths]).to eq(['vendor/ruby'])
        end
      end

      context 'with missing files' do
        let(:config) do
          {
            key: { files_commits: ['project-gemfile.lock', ''], prefix: 'a-prefix' },
            paths: ['vendor/ruby']
          }
        end

        it 'falls back to default key' do
          expect(subject).to include(
            key: 'a-prefix-default',
            paths: ['vendor/ruby']
          )
        end
      end
    end

    context 'with cache:fallback_keys' do
      let(:config) do
        {
          key: 'ruby-branch-key',
          paths: ['vendor/ruby'],
          fallback_keys: ['ruby-default']
        }
      end

      it 'includes fallback keys in attributes' do
        expect(subject).to include(config)
      end
    end

    context 'with all cache options' do
      let(:config) do
        {
          key: 'a-key',
          paths: ['vendor/ruby'],
          untracked: true,
          policy: 'push',
          unprotect: true,
          when: 'on_success',
          fallback_keys: ['default-ruby']
        }
      end

      it 'includes all cache options in attributes' do
        expect(subject).to include(config)
      end
    end

    context 'with unknown cache options' do
      let(:config) { { key: 'a-key', unknown_key: true } }

      it 'raises ArgumentError for unknown keys' do
        expect { subject }.to raise_error(ArgumentError, /unknown_key/)
      end
    end
  end
end
