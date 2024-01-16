# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Workflow, feature_category: :pipeline_composition do
  subject(:config) { described_class.new(workflow_hash) }

  describe 'validations' do
    before do
      config.compose!
    end

    context 'when work config value is a string' do
      let(:workflow_hash) { 'build' }

      describe '#valid?' do
        it 'is invalid' do
          expect(config).not_to be_valid
        end

        it 'attaches an error specifying that workflow should point to a hash' do
          expect(config.errors).to include('workflow config should be a hash')
        end
      end

      describe '#value' do
        it 'returns the invalid configuration' do
          expect(config.value).to eq(workflow_hash)
        end
      end
    end

    context 'when work config value is a hash' do
      context 'with an invalid key' do
        let(:workflow_hash) { { trash: [{ if: '$VAR' }] } }

        describe '#valid?' do
          it 'is invalid' do
            expect(config).not_to be_valid
          end

          it 'attaches an error specifying the unknown key' do
            expect(config.errors).to include('workflow config contains unknown keys: trash')
          end
        end

        describe '#value' do
          it 'returns the invalid configuration' do
            expect(config.value).to eq(workflow_hash)
          end
        end
      end
    end

    context 'when config has rules' do
      let(:workflow_hash) { { rules: [{ if: '$VAR' }] } }

      describe '#valid?' do
        it 'is valid' do
          expect(config).to be_valid
        end

        it 'attaches no errors' do
          expect(config.errors).to be_empty
        end
      end

      describe '#value' do
        it 'returns the config' do
          expect(config.value).to eq(workflow_hash)
        end
      end

      context 'when rules has an invalid key' do
        let(:workflow_hash) { { rules: [{ if: '$VAR', trash: 'something' }] } }

        describe '#valid?' do
          it 'is invalid' do
            expect(config).not_to be_valid
          end

          it 'attaches an error specifying the unknown key' do
            expect(config.errors).to include('rules:rule config contains unknown keys: trash')
          end
        end

        describe '#value' do
          it 'returns the invalid configuration' do
            expect(config.value).to eq(workflow_hash)
          end
        end
      end

      context 'when rules has auto_cancel' do
        let(:workflow_hash) { { rules: [{ if: '$VAR', auto_cancel: { on_new_commit: 'interruptible' } }] } }

        describe '#valid?' do
          it 'is valid' do
            expect(config).to be_valid
          end

          it 'attaches no errors' do
            expect(config.errors).to be_empty
          end
        end

        describe '#value' do
          it 'returns the config' do
            expect(config.value).to eq(workflow_hash)
          end
        end

        context 'when auto_cancel has an invalid value' do
          let(:workflow_hash) { { rules: [{ if: '$VAR', auto_cancel: { on_new_commit: 'xyz' } }] } }

          describe '#valid?' do
            it 'is invalid' do
              expect(config).not_to be_valid
            end

            it 'returns error' do
              expect(config.errors).to include(
                'rules:rule:auto_cancel on new commit must be one of: conservative, interruptible, none')
            end
          end
        end
      end
    end
  end

  describe '.default' do
    it 'is nil' do
      expect(described_class.default).to be_nil
    end
  end

  context 'with workflow name' do
    context 'with a blank name' do
      let(:workflow_hash) do
        { name: '' }
      end

      it 'is invalid' do
        expect(config).not_to be_valid
      end

      it 'returns error about invalid name' do
        expect(config.errors).to include('workflow name is too short (minimum is 1 character)')
      end
    end

    context 'with too long name' do
      let(:workflow_hash) do
        { name: 'a' * 256 }
      end

      it 'is invalid' do
        expect(config).not_to be_valid
      end

      it 'returns error about invalid name' do
        expect(config.errors).to include('workflow name is too long (maximum is 255 characters)')
      end
    end

    context 'when name is nil' do
      let(:workflow_hash) { { name: nil } }

      it 'is valid' do
        expect(config).to be_valid
      end
    end

    context 'when name is not provided' do
      let(:workflow_hash) { { rules: [{ if: '$VAR' }] } }

      it 'is valid' do
        expect(config).to be_valid
      end
    end
  end

  context 'with auto_cancel' do
    let(:workflow_hash) do
      {
        auto_cancel: {
          on_new_commit: 'interruptible',
          on_job_failure: 'none'
        }
      }
    end

    it { is_expected.to be_valid }

    it 'returns value correctly' do
      expect(config.value).to eq(workflow_hash)
    end
  end
end
