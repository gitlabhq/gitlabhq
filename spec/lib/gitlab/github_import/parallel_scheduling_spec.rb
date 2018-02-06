require 'spec_helper'

describe Gitlab::GithubImport::ParallelScheduling do
  let(:importer_class) do
    Class.new do
      include(Gitlab::GithubImport::ParallelScheduling)

      def collection_method
        :issues
      end
    end
  end

  let(:project) { double(:project, id: 4, import_source: 'foo/bar') }
  let(:client) { double(:client) }

  describe '#parallel?' do
    it 'returns true when running in parallel mode' do
      expect(importer_class.new(project, client)).to be_parallel
    end

    it 'returns false when running in sequential mode' do
      importer = importer_class.new(project, client, parallel: false)

      expect(importer).not_to be_parallel
    end
  end

  describe '#execute' do
    it 'imports data in parallel when running in parallel mode' do
      importer = importer_class.new(project, client)
      waiter = double(:waiter)

      expect(importer)
        .to receive(:parallel_import)
        .and_return(waiter)

      expect(importer.execute)
        .to eq(waiter)
    end

    it 'imports data in parallel when running in sequential mode' do
      importer = importer_class.new(project, client, parallel: false)

      expect(importer)
        .to receive(:sequential_import)
        .and_return([])

      expect(importer.execute)
        .to eq([])
    end

    it 'expires the cache used for tracking already imported objects' do
      importer = importer_class.new(project, client)

      expect(importer).to receive(:parallel_import)

      expect(Gitlab::GithubImport::Caching)
        .to receive(:expire)
        .with(importer.already_imported_cache_key, a_kind_of(Numeric))

      importer.execute
    end
  end

  describe '#sequential_import' do
    let(:importer) { importer_class.new(project, client, parallel: false) }

    it 'imports data in sequence' do
      repr_class = double(:representation_class)
      repr_instance = double(:representation_instance)
      gh_importer = double(:github_importer)
      gh_importer_instance = double(:github_importer_instance)
      object = double(:object)

      expect(importer)
        .to receive(:each_object_to_import)
        .and_yield(object)

      expect(importer)
        .to receive(:representation_class)
        .and_return(repr_class)

      expect(repr_class)
        .to receive(:from_api_response)
        .with(object)
        .and_return(repr_instance)

      expect(importer)
        .to receive(:importer_class)
        .and_return(gh_importer)

      expect(gh_importer)
        .to receive(:new)
        .with(repr_instance, project, client)
        .and_return(gh_importer_instance)

      expect(gh_importer_instance)
        .to receive(:execute)

      importer.sequential_import
    end
  end

  describe '#parallel_import' do
    let(:importer) { importer_class.new(project, client) }

    it 'imports data in parallel' do
      repr_class = double(:representation)
      worker_class = double(:worker)
      object = double(:object)

      expect(importer)
        .to receive(:each_object_to_import)
        .and_yield(object)

      expect(importer)
        .to receive(:representation_class)
        .and_return(repr_class)

      expect(importer)
        .to receive(:sidekiq_worker_class)
        .and_return(worker_class)

      expect(repr_class)
        .to receive(:from_api_response)
        .with(object)
        .and_return({ title: 'Foo' })

      expect(worker_class)
        .to receive(:perform_async)
        .with(project.id, { title: 'Foo' }, an_instance_of(String))

      expect(importer.parallel_import)
        .to be_an_instance_of(Gitlab::JobWaiter)
    end
  end

  describe '#each_object_to_import' do
    let(:importer) { importer_class.new(project, client) }
    let(:object) { double(:object) }

    before do
      expect(importer)
        .to receive(:collection_options)
        .and_return({ state: 'all' })
    end

    it 'yields every object to import' do
      page = double(:page, objects: [object], number: 1)

      expect(client)
        .to receive(:each_page)
        .with(:issues, 'foo/bar', { state: 'all', page: 1 })
        .and_yield(page)

      expect(importer.page_counter)
        .to receive(:set)
        .with(1)
        .and_return(true)

      expect(importer)
        .to receive(:already_imported?)
        .with(object)
        .and_return(false)

      expect(importer)
        .to receive(:mark_as_imported)
        .with(object)

      expect { |b| importer.each_object_to_import(&b) }
        .to yield_with_args(object)
    end

    it 'resumes from the last page' do
      page = double(:page, objects: [object], number: 2)

      expect(importer.page_counter)
        .to receive(:current)
        .and_return(2)

      expect(client)
        .to receive(:each_page)
        .with(:issues, 'foo/bar', { state: 'all', page: 2 })
        .and_yield(page)

      expect(importer.page_counter)
        .to receive(:set)
        .with(2)
        .and_return(true)

      expect(importer)
        .to receive(:already_imported?)
        .with(object)
        .and_return(false)

      expect(importer)
        .to receive(:mark_as_imported)
        .with(object)

      expect { |b| importer.each_object_to_import(&b) }
        .to yield_with_args(object)
    end

    it 'does not yield any objects if the page number was not set' do
      page = double(:page, objects: [object], number: 1)

      expect(client)
        .to receive(:each_page)
        .with(:issues, 'foo/bar', { state: 'all', page: 1 })
        .and_yield(page)

      expect(importer.page_counter)
        .to receive(:set)
        .with(1)
        .and_return(false)

      expect { |b| importer.each_object_to_import(&b) }
        .not_to yield_control
    end

    it 'does not yield the object if it was already imported' do
      page = double(:page, objects: [object], number: 1)

      expect(client)
        .to receive(:each_page)
        .with(:issues, 'foo/bar', { state: 'all', page: 1 })
        .and_yield(page)

      expect(importer.page_counter)
        .to receive(:set)
        .with(1)
        .and_return(true)

      expect(importer)
        .to receive(:already_imported?)
        .with(object)
        .and_return(true)

      expect(importer)
        .not_to receive(:mark_as_imported)

      expect { |b| importer.each_object_to_import(&b) }
        .not_to yield_control
    end
  end

  describe '#already_imported?', :clean_gitlab_redis_cache do
    let(:importer) { importer_class.new(project, client) }

    it 'returns false when an object has not yet been imported' do
      object = double(:object, id: 10)

      expect(importer)
        .to receive(:id_for_already_imported_cache)
        .with(object)
        .and_return(object.id)

      expect(importer.already_imported?(object))
        .to eq(false)
    end

    it 'returns true when an object has already been imported' do
      object = double(:object, id: 10)

      allow(importer)
        .to receive(:id_for_already_imported_cache)
        .with(object)
        .and_return(object.id)

      importer.mark_as_imported(object)

      expect(importer.already_imported?(object))
        .to eq(true)
    end
  end

  describe '#mark_as_imported', :clean_gitlab_redis_cache do
    it 'marks an object as already imported' do
      object = double(:object, id: 10)
      importer = importer_class.new(project, client)

      expect(importer)
        .to receive(:id_for_already_imported_cache)
        .with(object)
        .and_return(object.id)

      expect(Gitlab::GithubImport::Caching)
        .to receive(:set_add)
        .with(importer.already_imported_cache_key, object.id)
        .and_call_original

      importer.mark_as_imported(object)
    end
  end
end
