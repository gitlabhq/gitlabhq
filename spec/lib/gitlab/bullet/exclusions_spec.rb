# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Bullet::Exclusions do
  let(:config_file) do
    file = Tempfile.new('bullet.yml')
    File.basename(file)
  end

  let(:exclude) { [] }
  let(:config) do
    {
      exclusions: {
        abc: {
          merge_request: '_mr_',
          path_with_method: true,
          exclude: exclude
        }
      }
    }
  end

  before do
    File.write(config_file, config.deep_stringify_keys.to_yaml)
  end

  after do
    FileUtils.rm_f(config_file)
  end

  describe '#execute' do
    subject(:executor) { described_class.new(config_file).execute }

    shared_examples_for 'loads exclusion results' do
      let(:config) { { exclusions: { abc: { exclude: exclude } } } }
      let(:results) { [exclude] }

      specify do
        expect(executor).to match(results)
      end
    end

    context 'with preferred method of path and method name' do
      it_behaves_like 'loads exclusion results' do
        let(:exclude) { %w[_path_ _method_] }
      end
    end

    context 'with file pattern' do
      it_behaves_like 'loads exclusion results' do
        let(:exclude) { ['_file_pattern_'] }
      end
    end

    context 'with file name and line range' do
      it_behaves_like 'loads exclusion results' do
        let(:exclude) { ['file_name.rb', 5..10] }
      end
    end

    context 'without exclusions' do
      it_behaves_like 'loads exclusion results' do
        let(:exclude) { [] }
      end
    end

    context 'without exclusions key in config' do
      it_behaves_like 'loads exclusion results' do
        let(:config) { {} }
        let(:results) { [] }
      end
    end

    context 'when config file does not exist' do
      it 'provides an empty array for exclusions' do
        expect(described_class.new('_some_bogus_file_').execute).to match([])
      end
    end
  end

  describe '#validate_paths!' do
    context 'when validating scenarios' do
      let(:source_file) do
        file = Tempfile.new('bullet_test_source_file.rb')
        File.basename(file)
      end

      subject { described_class.new(config_file).validate_paths! }

      before do
        FileUtils.touch(source_file)
      end

      after do
        FileUtils.rm_f(source_file)
      end

      context 'when using paths with method name' do
        let(:exclude) { [source_file, '_method_'] }

        context 'when source file for exclusion exists' do
          specify do
            expect { subject }.not_to raise_error
          end
        end

        context 'when source file for exclusion does not exist' do
          let(:exclude) { %w[_bogus_file_ _method_] }

          specify do
            expect { subject }.to raise_error(RuntimeError)
          end
        end
      end

      context 'when using path only' do
        let(:exclude) { [source_file] }

        context 'when source file for exclusion exists' do
          specify do
            expect { subject }.not_to raise_error
          end
        end

        context 'when source file for exclusion does not exist' do
          let(:exclude) { '_bogus_file_' }

          specify do
            expect { subject }.to raise_error(RuntimeError)
          end
        end
      end

      context 'when path_with_method is false for a file pattern' do
        let(:exclude) { ['_file_pattern_'] }
        let(:config) do
          {
            exclusions: {
              abc: {
                merge_request: '_mr_',
                path_with_method: false,
                exclude: exclude
              }
            }
          }
        end

        specify do
          expect { subject }.not_to raise_error
        end
      end
    end
  end
end
