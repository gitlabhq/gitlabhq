require 'spec_helper'

describe Gitlab::GithubImport::ObjectImporter do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include(Gitlab::GithubImport::ObjectImporter)

      def counter_name
        :dummy_counter
      end

      def counter_description
        'This is a counter'
      end
    end.new
  end

  describe '#import' do
    it 'imports the object' do
      representation_class = double(:representation_class)
      importer_class = double(:importer_class)
      importer_instance = double(:importer_instance)
      representation = double(:representation)
      project = double(:project, full_path: 'foo/bar')
      client = double(:client)

      expect(worker)
        .to receive(:representation_class)
        .and_return(representation_class)

      expect(worker)
        .to receive(:importer_class)
        .and_return(importer_class)

      expect(representation_class)
        .to receive(:from_json_hash)
        .with(an_instance_of(Hash))
        .and_return(representation)

      expect(importer_class)
        .to receive(:new)
        .with(representation, project, client)
        .and_return(importer_instance)

      expect(importer_instance)
        .to receive(:execute)

      expect(worker.counter)
        .to receive(:increment)
        .with(project: 'foo/bar')
        .and_call_original

      worker.import(project, client, { 'number' => 10 })
    end
  end

  describe '#counter' do
    it 'returns a Prometheus counter' do
      expect(worker)
        .to receive(:counter_name)
        .and_call_original

      expect(worker)
        .to receive(:counter_description)
        .and_call_original

      worker.counter
    end
  end
end
