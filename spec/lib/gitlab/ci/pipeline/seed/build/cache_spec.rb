# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Build::Cache do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:head_sha) { project.repository.head_commit.id }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: head_sha) }

  let(:processor) { described_class.new(pipeline, config) }

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

      it { is_expected.to include(config.merge(key: "a_key")) }
    end

    context 'with cache:key:files' do
      shared_examples 'default key' do
        let(:config) do
          { key: { files: files } }
        end

        it 'uses default key' do
          expected = { key: 'default' }

          is_expected.to include(expected)
        end
      end

      shared_examples 'version and gemfile files' do
        let(:config) do
          {
            key: {
              files: files
            },
            paths: ['vendor/ruby']
          }
        end

        it 'builds a string key' do
          expected = {
                key: '703ecc8fef1635427a1f86a8a1a308831c122392',
                paths: ['vendor/ruby']
            }

          is_expected.to include(expected)
        end
      end

      context 'with existing files' do
        let(:files) { ['VERSION', 'Gemfile.zip'] }

        it_behaves_like 'version and gemfile files'
      end

      context 'with files starting with ./' do
        let(:files) { ['Gemfile.zip', './VERSION'] }

        it_behaves_like 'version and gemfile files'
      end

      context 'with files ending with /' do
        let(:files) { ['Gemfile.zip/'] }

        it_behaves_like 'default key'
      end

      context 'with new line in filenames' do
        let(:files) { ["Gemfile.zip\nVERSION"] }

        it_behaves_like 'default key'
      end

      context 'with missing files' do
        let(:files) { ['project-gemfile.lock', ''] }

        it_behaves_like 'default key'
      end

      context 'with directories' do
        shared_examples 'foo/bar directory key' do
          let(:config) do
            {
              key: {
                files: files
              }
            }
          end

          it 'builds a string key' do
            expected = { key: '74bf43fb1090f161bdd4e265802775dbda2f03d1' }

            is_expected.to include(expected)
          end
        end

        context 'with directory' do
          let(:files) { ['foo/bar'] }

          it_behaves_like 'foo/bar directory key'
        end

        context 'with directory ending in slash' do
          let(:files) { ['foo/bar/'] }

          it_behaves_like 'foo/bar directory key'
        end

        context 'with directories ending in slash star' do
          let(:files) { ['foo/bar/*'] }

          it_behaves_like 'foo/bar directory key'
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
          expected = {
                key: 'a-prefix-703ecc8fef1635427a1f86a8a1a308831c122392',
                paths: ['vendor/ruby']
              }

          is_expected.to include(expected)
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

    context 'with all cache option keys' do
      let(:config) do
        {
          key: 'a-key',
          paths: ['vendor/ruby'],
          untracked: true,
          policy: 'push',
          when: 'on_success'
        }
      end

      it { is_expected.to include(config) }
    end

    context 'with unknown cache option keys' do
      let(:config) do
        {
          key: 'a-key',
          unknown_key: true
        }
      end

      it { expect { subject }.to raise_error(ArgumentError, /unknown_key/) }
    end
  end
end
