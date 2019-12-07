# frozen_string_literal: true

require 'spec_helper'

describe 'Direct upload support' do
  subject do
    load Rails.root.join('config/initializers/direct_upload_support.rb')
  end

  where(:config_name) do
    %w(lfs artifacts uploads)
  end

  with_them do
    let(:connection) do
      { provider: provider }
    end

    let(:object_store) do
      {
        enabled: enabled,
        direct_upload: direct_upload,
        connection: connection
      }
    end

    before do
      allow(Gitlab.config).to receive_messages(to_settings(config_name => {
        object_store: object_store
      }))
    end

    context 'when object storage is enabled' do
      let(:enabled) { true }

      context 'when direct upload is enabled' do
        let(:direct_upload) { true }

        context 'when provider is AWS' do
          let(:provider) { 'AWS' }

          it 'succeeds' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when provider is Google' do
          let(:provider) { 'Google' }

          it 'succeeds' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when connection is empty' do
          let(:connection) { nil }

          it 'raises an error' do
            expect { subject }.to raise_error "No provider configured for '#{config_name}'. Only Google, AWS are supported."
          end
        end

        context 'when other provider is used' do
          let(:provider) { 'Rackspace' }

          it 'raises an error' do
            expect { subject }.to raise_error /Object storage provider '#{provider}' is not supported when 'direct_upload' is used for '#{config_name}'/
          end
        end

        context 'when connection is omitted' do
          let(:object_store) do
            {
              enabled: enabled,
              direct_upload: direct_upload
            }
          end

          it 'raises an error' do
            expect { subject }.to raise_error /the 'connection' section is missing/
          end
        end
      end

      context 'when direct upload is disabled' do
        let(:direct_upload) { false }
        let(:provider) { 'AWS' }

        it 'succeeds' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'when object storage is disabled' do
      let(:enabled) { false }
      let(:direct_upload) { false }
      let(:provider) { 'Rackspace' }

      it 'succeeds' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
