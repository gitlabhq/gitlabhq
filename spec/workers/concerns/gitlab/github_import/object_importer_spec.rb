# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ObjectImporter do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include(Gitlab::GithubImport::ObjectImporter)

      def object_type
        :dummy
      end

      def representation_class
        MockRepresantation
      end
    end.new
  end

  before do
    stub_const('MockRepresantation', Class.new do
      include Gitlab::GithubImport::Representation::ToHash
      include Gitlab::GithubImport::Representation::ExposeAttribute

      def self.from_json_hash(raw_hash)
        new(Gitlab::GithubImport::Representation.symbolize_hash(raw_hash))
      end

      attr_reader :attributes

      def initialize(attributes)
        @attributes = attributes
      end
    end)
  end

  describe '#import', :clean_gitlab_redis_shared_state do
    let(:importer_class) { double(:importer_class, name: 'klass_name') }
    let(:importer_instance) { double(:importer_instance) }
    let(:project) { double(:project, full_path: 'foo/bar', id: 1) }
    let(:client) { double(:client) }

    before do
      expect(worker)
        .to receive(:importer_class)
        .at_least(:once)
        .and_return(importer_class)
    end

    it 'imports the object' do
      expect(importer_class)
        .to receive(:new)
        .with(instance_of(MockRepresantation), project, client)
        .and_return(importer_instance)

      expect(importer_instance)
        .to receive(:execute)

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(
            github_id: 1,
            message: 'starting importer',
            import_source: :github,
            project_id: 1,
            importer: 'klass_name'
          )
        expect(logger)
          .to receive(:info)
          .with(
            github_id: 1,
            message: 'importer finished',
            import_source: :github,
            project_id: 1,
            importer: 'klass_name'
          )
      end

      worker.import(project, client, { 'number' => 10, 'github_id' => 1 })

      expect(Gitlab::GithubImport::ObjectCounter.summary(project)).to eq({
        'fetched' => {},
        'imported' => { 'dummy' => 1 }
      })
    end

    it 'logs error when the import fails' do
      expect(importer_class)
        .to receive(:new)
        .with(instance_of(MockRepresantation), project, client)
        .and_return(importer_instance)

      exception = StandardError.new('some error')
      expect(importer_instance)
        .to receive(:execute)
        .and_raise(exception)

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(
            github_id: 1,
            message: 'starting importer',
            import_source: :github,
            project_id: project.id,
            importer: 'klass_name'
          )
        expect(logger)
          .to receive(:error)
          .with(
            github_id:  1,
            message: 'importer failed',
            import_source: :github,
            project_id: project.id,
            importer: 'klass_name',
            'error.message': 'some error',
            'github.data': {
              'github_id' => 1,
              'number' => 10
            }
          )
      end

      expect(Gitlab::ErrorTracking)
        .to receive(:track_and_raise_exception)
        .with(
          exception,
          import_source: :github,
          github_id: 1,
          project_id: 1,
          importer: 'klass_name'
        ).and_call_original

      expect { worker.import(project, client, { 'number' => 10, 'github_id' => 1 }) }
        .to raise_error(exception)
    end

    it 'logs error when representation does not have a github_id' do
      expect(importer_class).not_to receive(:new)

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:error)
          .with(
            github_id:  nil,
            message: 'importer failed',
            import_source: :github,
            project_id: project.id,
            importer: 'klass_name',
            'error.message': 'key not found: :github_id',
            'github.data': {
              'number' => 10
            }
          )
      end

      expect(Gitlab::ErrorTracking)
        .to receive(:track_and_raise_exception)
        .with(
          an_instance_of(KeyError),
          import_source: :github,
          github_id: nil,
          project_id: 1,
          importer: 'klass_name'
        ).and_call_original

      expect { worker.import(project, client, { 'number' => 10 }) }
        .to raise_error(KeyError, 'key not found: :github_id')
    end
  end
end
