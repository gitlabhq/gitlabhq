# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::S3, feature_category: :source_code_management do
  describe '.signed_head_url' do
    subject { described_class.signed_head_url(package_file.file) }

    let(:package_file) { create(:package_file) }

    context 'when the provider is AWS' do
      before do
        stub_lfs_object_storage(config: Gitlab.config.lfs.object_store.merge(
          connection: {
            provider: 'AWS',
            aws_access_key_id: 'test',
            aws_secret_access_key: 'test'
          }
        ))
      end

      it 'generates a signed url' do
        expect_next_instance_of(Fog::AWS::Storage::Files) do |instance|
          expect(instance).to receive(:head_url).and_return(a_valid_url)
        end

        subject
      end

      it 'delegates to Fog::AWS::Storage::Files#head_url' do
        expect_next_instance_of(Fog::AWS::Storage::Files) do |instance|
          expect(instance).to receive(:head_url).and_return('stubbed_url')
        end

        expect(subject).to eq('stubbed_url')
      end
    end
  end
end
