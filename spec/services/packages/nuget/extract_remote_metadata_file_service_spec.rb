# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::ExtractRemoteMetadataFileService, feature_category: :package_registry do
  let_it_be(:remote_url) { 'http://example.com/package.nupkg' }
  let_it_be(:nupkg_filepath) { 'packages/nuget/package.nupkg' }

  let(:service) { described_class.new(remote_url) }

  describe '#execute' do
    subject { service.execute }

    context 'when the remote URL is blank' do
      let(:remote_url) { '' }

      it { is_expected.to be_error.and have_attributes(message: 'invalid file url') }
    end

    context 'when the package file is corrupted' do
      before do
        allow(Gitlab::HTTP).to receive(:get).with(remote_url, stream_body: true, allow_object_storage: true)
          .and_yield('corrupted data')
      end

      it { is_expected.to be_error.and have_attributes(message: 'nuspec file not found') }
    end

    context 'when reaching the maximum received fragments' do
      before do
        allow(Gitlab::HTTP).to receive(:get).with(remote_url, stream_body: true, allow_object_storage: true)
          .and_yield('Fragment 1').and_yield('Fragment 2').and_yield('Fragment 3').and_yield('Fragment 4')
          .and_yield('Fragment 5').and_yield(fixture_file(nupkg_filepath))
      end

      it { is_expected.to be_error.and have_attributes(message: 'nuspec file not found') }
    end

    context 'when nuspec file is too big' do
      before do
        allow(Gitlab::HTTP).to receive(:get).with(remote_url, stream_body: true, allow_object_storage: true)
          .and_yield(fixture_file(nupkg_filepath))
        allow_next_instance_of(Zip::Entry) do |instance|
          allow(instance).to receive(:size).and_return(6.megabytes)
        end
      end

      it { is_expected.to be_error.and have_attributes(message: 'nuspec file too big') }
    end

    context 'when nuspec file is fragmented' do
      let_it_be(:nuspec_path) { expand_fixture_path('packages/nuget/with_metadata.nuspec') }
      let_it_be(:tmp_zip) { Tempfile.new('nuget_zip') }
      let_it_be(:zipped_nuspec) { zip_nuspec_file(nuspec_path, tmp_zip.path).get_raw_input_stream.read }
      let_it_be(:fragments) { zipped_nuspec.chars.each_slice(zipped_nuspec.size / 2).map(&:join) }

      before do
        allow(Gitlab::HTTP).to receive(:get).with(remote_url, stream_body: true, allow_object_storage: true)
          .and_yield(fragments[0]).and_yield(fragments[1])
      end

      after do
        tmp_zip.unlink
      end

      it 'ignores the Zip::DecompressionError and constructs the nuspec file from the fragments' do
        response = service.execute

        expect(response).to be_success
        expect(response.payload).to include('<id>DummyProject.WithMetadata</id>')
          .and include('<version>1.2.3</version>')
      end
    end

    context 'when the remote URL is valid' do
      let(:fragments) { fixture_file(nupkg_filepath).chars.each_slice(1.kilobyte).map(&:join) }

      before do
        allow(Gitlab::HTTP).to receive(:get).with(remote_url, stream_body: true, allow_object_storage: true)
          .and_yield(fragments[0]).and_yield(fragments[1]).and_yield(fragments[2]).and_yield(fragments[3])
      end

      it 'returns a success response with the nuspec file content' do
        response = service.execute

        expect(response).to be_success
        expect(response.payload).to include('<id>DummyProject.DummyPackage</id>')
          .and include('<version>1.0.0</version>')
      end
    end

    context 'with a corrupted nupkg file with a wrong entry size' do
      before do
        allow(Gitlab::HTTP).to receive(:get).with(remote_url, stream_body: true, allow_object_storage: true)
          .and_yield(fixture_file(nupkg_filepath))
        allow_next_instance_of(Zip::Entry) do |instance|
          allow(instance).to receive(:extract).and_raise(Zip::EntrySizeError)
        end
      end

      it { is_expected.to be_error.and have_attributes(message: /nuspec file has the wrong entry size/) }
    end

    context 'with a Zip::Error exception' do
      before do
        allow(Gitlab::HTTP).to receive(:get).with(remote_url, stream_body: true, allow_object_storage: true)
          .and_yield(fixture_file(nupkg_filepath))
        allow(Zip::InputStream).to receive(:open).and_raise(Zip::Error)
      end

      it { is_expected.to be_error.and have_attributes(message: /Error opening zip stream/) }
    end
  end

  def zip_nuspec_file(nuspec_path, zip_path)
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      zipfile.add('package.nuspec', nuspec_path)
    end
  end
end
