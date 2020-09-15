# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StaticSiteEditor::ConfigService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  # params
  let(:ref) { double(:ref) }
  let(:path) { double(:path) }
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

        allow_next_instance_of(Gitlab::StaticSiteEditor::Config::FileConfig) do |config|
          allow(config).to receive(:data) { file_data }
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
