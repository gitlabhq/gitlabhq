# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SupplyChain::ArtifactsReader, feature_category: :artifact_security do
  let(:reader) { described_class.new(build) }

  describe 'when build has artifacts' do
    include_context 'with build, pipeline and artifacts'

    it 'reads files correctly' do
      files = {}
      reader.files do |filename, file|
        files[filename] = file.read
      end

      expect(files.length).to eq(3)
      expect(files).to include(match(/artifact.txt$/))
      expect(files).to include(match(/artifact.zip$/))
      expect(files).to include(match(/file.txt$/))
      expect(files["artifact.txt"]).to eq("Hello, world\n")
      expect(files["artifact.zip"]).to eq("PK\u0005\u0006\u0000\u0000\u0000\u0000\u0000\u0000" \
        "\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000(\u0000fc8e0d59c1cc5c14b6919fb2006b27fe337e7d0e")
      expect(files["output/recursive/file.txt"]).to eq("1337\n")
    end

    it 'deletes files immediately after use' do
      previous_file = nil
      reader.files do |file|
        expect(File.file?(previous_file)).to be(false) if previous_file
        previous_file = file
      end

      expect(File.file?(previous_file)).to be(false)
    end

    context 'when the bundle is too large' do
      before do
        allow(build.job_artifacts_archive).to receive(:size).and_return(described_class::MAX_SIZE + 1)
      end

      it 'fails with an exception' do
        expect { reader.files }.to raise_error(described_class::BundleTooLarge)
      end
    end

    context 'when the artifact file is too large' do
      before do
        metadata = instance_double(Gitlab::Ci::Build::Artifacts::Metadata::Entry)
        entries = {
          "artifact.txt" => {
            size: described_class::MAX_SIZE + 1
          }
        }

        allow(build).to receive(:artifacts_metadata_entry).with(anything, anything).and_return(metadata)
        allow(metadata).to receive(:entries).and_return(entries)
      end

      it 'fails with an exception' do
        expect { reader.files }.to raise_error(described_class::ArtifactTooLarge)
      end
    end

    context 'when disk is full' do
      it 'fails with an exception if ENOSPC' do
        expect(build.artifacts_file).to receive(:use_open_file).and_raise(Errno::ENOSPC)
        expect { reader.files }.to raise_error(described_class::DiskFull)
      end

      it 'fails with an exception if EDQUOT' do
        expect(build.artifacts_file).to receive(:use_open_file).and_raise(Errno::EDQUOT)
        expect { reader.files }.to raise_error(described_class::DiskFull)
      end

      it 'passes through other Errno exceptions' do
        expect(build.artifacts_file).to receive(:use_open_file).and_raise(Errno::ENOENT)
        expect { reader.files }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when there are too many files within the artifact bundle' do
      it 'fails with the proper exception' do
        metadata = double
        entries = double
        expect(build).to receive(:artifacts_metadata_entry).with(anything, anything).and_return(metadata)
        expect(metadata).to receive(:entries).and_return(entries)
        expect(entries).to receive(:length).and_return(described_class::MAX_FILES_IN_BUNDLE + 1)

        expect { reader }.to raise_error(described_class::TooManyFiles)
      end
    end
  end

  context 'when the build does not have artifacts' do
    let_it_be(:build) do
      create(:ci_build, :finished)
    end

    it 'reads files correctly' do
      expect { reader.files }.to raise_exception(described_class::NoArtifacts)
    end
  end
end
