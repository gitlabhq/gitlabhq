require 'spec_helper'

describe 'Artifacts direct upload support' do
  subject do
    load Rails.root.join('config/initializers/artifacts_direct_upload_support.rb')
  end

  let(:connection) do
    { provider: provider }
  end

  before do
    stub_artifacts_setting(
      object_store: {
        enabled: enabled,
        direct_upload: direct_upload,
        connection: connection
      })
  end

  context 'when object storage is enabled' do
    let(:enabled) { true }

    context 'when direct upload is enabled' do
      let(:direct_upload) { true }

      context 'when provider is Google' do
        let(:provider) { 'Google' }

        it 'succeeds' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when connection is empty' do
        let(:connection) { nil }

        it 'raises an error' do
          expect { subject }.to raise_error /object storage provider when 'direct_upload' of artifacts is used/
        end
      end

      context 'when other provider is used' do
        let(:provider) { 'AWS' }

        it 'raises an error' do
          expect { subject }.to raise_error /object storage provider when 'direct_upload' of artifacts is used/
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
    let(:provider) { 'AWS' }

    it 'succeeds' do
      expect { subject }.not_to raise_error
    end
  end
end
