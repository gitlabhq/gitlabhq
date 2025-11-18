# frozen_string_literal: true

# Shared examples for External::Mapper and Header::Mapper
#
# These examples test common behavior across both mapper types.
# The including spec must define:
#   - mapper: instance of the mapper being tested
#   - values: the input hash to process
#   - context: the external context
#   - local_file: path to a local file
#   - remote_url: URL for remote file tests
#   - file_content: content to stub for remote files
#
RSpec.shared_examples 'processes local file includes' do
  context 'when the string is a local file' do
    let(:values) do
      { include: local_file,
        image: 'image:1.0' }
    end

    it 'returns File instances' do
      expect(subject).to contain_exactly(
        an_instance_of(Gitlab::Ci::Config::External::File::Local))
    end
  end

  context 'when the key is a local file hash' do
    let(:values) do
      { include: { 'local' => local_file },
        image: 'image:1.0' }
    end

    it 'returns File instances' do
      expect(subject).to contain_exactly(
        an_instance_of(Gitlab::Ci::Config::External::File::Local))
    end
  end
end

RSpec.shared_examples 'processes remote file includes' do
  context 'when the string is a remote file' do
    let(:values) do
      { include: remote_url, image: 'image:1.0' }
    end

    it 'returns File instances' do
      expect(subject).to contain_exactly(
        an_instance_of(Gitlab::Ci::Config::External::File::Remote))
    end
  end

  context 'when the key is a remote file hash' do
    let(:values) do
      { include: { 'remote' => remote_url },
        image: 'image:1.0' }
    end

    it 'returns File instances' do
      expect(subject).to contain_exactly(
        an_instance_of(Gitlab::Ci::Config::External::File::Remote))
    end
  end
end

RSpec.shared_examples 'processes project file includes' do
  context "when the key is a project's file" do
    let(:values) do
      { include: { project: project.full_path, file: local_file },
        image: 'image:1.0' }
    end

    it 'returns File instances' do
      expect(subject).to contain_exactly(
        an_instance_of(Gitlab::Ci::Config::External::File::Project))
    end
  end
end

RSpec.shared_examples 'handles empty includes' do
  context "when 'include' is not defined" do
    let(:values) do
      {
        image: 'image:1.0'
      }
    end

    it 'returns an empty array' do
      expect(subject).to be_empty
    end
  end
end

RSpec.shared_examples 'handles invalid include types' do
  context 'when the include value is a Boolean' do
    let(:values) { { include: true } }

    it 'raises an error' do
      expect { mapper.process }.to raise_error(
        Gitlab::Ci::Config::External::Mapper::InvalidTypeError, /Each include must be a hash or a string/)
    end
  end

  context 'when an include value is an Array' do
    let(:values) { { include: [remote_url, [local_file]] } }

    it 'raises an error' do
      expect { mapper.process }.to raise_error(
        Gitlab::Ci::Config::External::Mapper::InvalidTypeError, /Each include must be a hash or a string/)
    end
  end
end

RSpec.shared_examples 'handles ambiguous specifications' do
  context 'when the key is not valid' do
    let(:local_file) { 'secret-file.yml' }
    let(:values) do
      { include: { invalid: local_file },
        image: 'image:1.0' }
    end

    it 'returns ambigious specification error' do
      expect { subject }.to raise_error(
        described_class::AmbigiousSpecificationError,
        /does not have a valid subkey for.*include/
      )
    end
  end

  context 'when the key is a hash of local and remote' do
    let(:local_file) { 'secret-file.yml' }
    let(:remote_url) { 'https://gitlab.com/secret-file.yml' }
    let(:values) do
      { include: { 'local' => local_file, 'remote' => remote_url },
        image: 'image:1.0' }
    end

    it 'returns ambigious specification error' do
      expect { subject }.to raise_error(
        described_class::AmbigiousSpecificationError,
        /Each include must use only one of/
      )
    end
  end
end

RSpec.shared_examples 'processes array of includes' do
  context "when 'include' is defined as an array" do
    let(:values) do
      { include: [remote_url, local_file],
        image: 'image:1.0' }
    end

    it 'returns Files instances' do
      expect(subject).to all(respond_to(:valid?))
      expect(subject).to all(respond_to(:content))
    end
  end

  context "when 'include' is defined as an array of hashes" do
    let(:values) do
      { include: [{ remote: remote_url }, { local: local_file }],
        image: 'image:1.0' }
    end

    it 'returns Files instances' do
      expect(subject).to all(respond_to(:valid?))
      expect(subject).to all(respond_to(:content))
    end
  end
end
