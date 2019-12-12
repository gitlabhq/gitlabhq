# frozen_string_literal: true

require 'spec_helper'

describe Backup::Uploads do
  let(:progress) { StringIO.new }

  subject(:backup) { described_class.new(progress) }

  describe '#initialize' do
    it 'uses the correct upload dir' do
      Dir.mktmpdir do |tmpdir|
        FileUtils.mkdir_p("#{tmpdir}/uploads")

        allow(Gitlab.config.uploads).to receive(:storage_path) { tmpdir }

        expect(backup.app_files_dir).to eq("#{tmpdir}/uploads")
      end
    end
  end
end
