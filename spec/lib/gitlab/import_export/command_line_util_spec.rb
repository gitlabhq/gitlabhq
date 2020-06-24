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
end
