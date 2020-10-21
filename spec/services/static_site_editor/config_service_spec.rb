# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StaticSiteEditor::ConfigService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  # params
  let(:ref) { 'master' }
  let(:path) { 'README.md' }
  let(:return_url) { double(:return_url) }

  # stub data
  let(:generated_data) { { generated: true } }
  let(:file_data) { { file: true } }

  describe '#execute' do
    subject(:execute) do
      described_class.new(
        container: project,
        current_user: user,
        params: {
          ref: ref,
          path: path,
          return_url: return_url
        }
      ).execute
    end

    context 'when insufficient permission' do
      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('Insufficient permissions to read configuration')
      end
    end

    context 'for developer' do
      before do
        project.add_developer(user)

        allow_next_instance_of(Gitlab::StaticSiteEditor::Config::GeneratedConfig) do |config|
          allow(config).to receive(:data) { generated_data }
        end
      end

      context 'when reading file from repo fails with an unexpected error' do
        let(:unexpected_error) { RuntimeError.new('some unexpected error') }

        before do
          allow(project.repository).to receive(:blob_data_at).and_raise(unexpected_error)
        end

        it 'returns an error response' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_exception).with(unexpected_error).and_call_original
          expect { execute }.to raise_error(unexpected_error)
        end
      end

      context 'when file is missing' do
        before do
          allow(project.repository).to receive(:blob_data_at).and_raise(GRPC::NotFound)
          expect_next_instance_of(Gitlab::StaticSiteEditor::Config::FileConfig, '{}') do |config|
            allow(config).to receive(:valid?) { true }
            allow(config).to receive(:to_hash_with_defaults) { file_data }
          end
        end

        it 'returns default config' do
          expect(execute).to be_success
          expect(execute.payload).to eq(generated: true, file: true)
        end
      end

      context 'when file is present' do
        before do
          allow(project.repository).to receive(:blob_data_at).with(ref, anything) do
            config_content
          end
        end

        context 'and configuration is not valid' do
          let(:config_content) { 'invalid content' }

          before do
            expect_next_instance_of(Gitlab::StaticSiteEditor::Config::FileConfig, config_content) do |config|
              error = 'error'
              allow(config).to receive_message_chain('errors.first') { error }
              allow(config).to receive(:valid?) { false }
            end
          end

          it 'returns an error' do
            expect(execute).to be_error
            expect(execute.message).to eq('Invalid configuration format')
          end
        end

        context 'and configuration is valid' do
          # NOTE: This has to be a valid config, even though it is mocked, because
          #       `expect_next_instance_of` executes the constructor logic.
          let(:config_content) { 'static_site_generator: middleman' }

          before do
            expect_next_instance_of(Gitlab::StaticSiteEditor::Config::FileConfig, config_content) do |config|
              allow(config).to receive(:valid?) { true }
              allow(config).to receive(:to_hash_with_defaults) { file_data }
            end
          end

          it 'returns merged generated data and config file data' do
            expect(execute).to be_success
            expect(execute.payload).to eq(generated: true, file: true)
          end

          it 'returns an error if any keys would be overwritten by the merge' do
            generated_data[:duplicate_key] = true
            file_data[:duplicate_key] = true
            expect(execute).to be_error
            expect(execute.message).to match(/duplicate key.*duplicate_key.*found/i)
          end
        end
      end
    end
  end
end
