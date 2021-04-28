# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::CommandLineUtil do
  include ExportFileHelper

  let(:path) { "#{Dir.tmpdir}/symlink_test" }
  let(:archive) { 'spec/fixtures/symlink_export.tar.gz' }
  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }

  subject do
    Class.new do
      include Gitlab::ImportExport::CommandLineUtil

      def initialize
        @shared = Gitlab::ImportExport::Shared.new(nil)
      end

      def execute_download(url)
        download(url, 'path')
      end
    end.new
  end

  before do
    FileUtils.mkdir_p(path)
    subject.untar_zxf(archive: archive, dir: path)
  end

  after do
    FileUtils.rm_rf(path)
  end

  it 'has the right mask for project.json' do
    expect(file_permissions("#{path}/project.json")).to eq(0755) # originally 777
  end

  it 'has the right mask for uploads' do
    expect(file_permissions("#{path}/uploads")).to eq(0755) # originally 555
  end

  context 'validates the URL before executing the download' do
    before do
      stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
    end

    it 'raises error when the given URL is blocked' do
      expect { subject.execute_download('http://localhost:3000/file') }
        .to raise_error(Gitlab::UrlBlocker::BlockedUrlError, 'Requests to localhost are not allowed')
    end

    it 'executes the download when the URL is allowed' do
      expect_next_instance_of(URI::HTTP) do |uri|
        expect(uri)
          .to receive(:open)
          .and_return('file content')
      end

      expect(IO)
        .to receive(:copy_stream)
        .with('file content', instance_of(File))

      subject.execute_download('http://some.url.remote/file')
    end
  end
end
