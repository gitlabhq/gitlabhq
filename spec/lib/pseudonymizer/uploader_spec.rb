require 'spec_helper'

describe Pseudonymizer::Uploader do
  let(:base_dir) { Dir.mktmpdir }
  let(:options) do
    Pseudonymizer::Options.new(
      config: YAML.load_file(Gitlab.config.pseudonymizer.manifest)
    )
  end
  let(:remote_directory) { subject.send(:remote_directory) }
  subject { described_class.new(options) }

  def mock_file(file_name)
    FileUtils.touch(File.join(base_dir, file_name))
  end

  before do
    allow(options).to receive(:output_dir).and_return(base_dir)
    stub_object_storage_pseudonymizer

    10.times {|i| mock_file("file_#{i}.test")}
    mock_file("schema.yml")
    mock_file("file_list.json")
  end

  after do
    FileUtils.rm_rf(base_dir)
  end

  describe "#upload" do
    it "upload all file in the directory" do
      subject.upload

      expect(remote_directory.files.all.count).to eq(12)
    end
  end

  describe "#cleanup" do
    it "cleans the directory" do
      subject.cleanup

      expect(Dir[File.join(base_dir, "*")].length).to eq(0)
    end
  end
end
