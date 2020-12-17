# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ObjectImporter do
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
    let(:representation_class) { double(:representation_class) }
    let(:importer_class) { double(:importer_class, name: 'klass_name') }
    let(:importer_instance) { double(:importer_instance) }
    let(:representation) { double(:representation) }
    let(:project) { double(:project, full_path: 'foo/bar', id: 1) }
    let(:client) { double(:client) }

    before do
      expect(worker)
        .to receive(:representation_class)
        .and_return(representation_class)

      expect(worker)
        .to receive(:importer_class)
        .at_least(:once)
        .and_return(importer_class)

      expect(representation_class)
        .to receive(:from_json_hash)
        .with(an_instance_of(Hash))
        .and_return(representation)

      expect(importer_class)
        .to receive(:new)
        .with(representation, project, client)
        .and_return(importer_instance)
    end

    it 'imports the object' do
      expect(importer_instance)
        .to receive(:execute)

      expect(worker.counter)
        .to receive(:increment)
        .and_call_original

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(
            message: 'starting importer',
            import_source: :github,
            project_id: 1,
            importer: 'klass_name'
          )
        expect(logger)
          .to receive(:info)
          .with(
            message: 'importer finished',
            import_source: :github,
            project_id: 1,
            importer: 'klass_name'
          )
      end

      worker.import(project, client, { 'number' => 10 })
    end

    it 'logs error when the import fails' do
      exception = StandardError.new('some error')
      expect(importer_instance)
        .to receive(:execute)
        .and_raise(exception)

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(
            message: 'starting importer',
            import_source: :github,
            project_id: project.id,
            importer: 'klass_name'
          )
        expect(logger)
          .to receive(:error)
          .with(
            message: 'importer failed',
            import_source: :github,
            project_id: project.id,
            importer: 'klass_name',
            'error.message': 'some error'
          )
      end

      expect(Gitlab::ErrorTracking)
        .to receive(:track_and_raise_exception)
        .with(exception, import_source: :github, project_id: 1, importer: 'klass_name')
        .and_call_original

      expect { worker.import(project, client, { 'number' => 10 }) }.to raise_error(exception)
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
