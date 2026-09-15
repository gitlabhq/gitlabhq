# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::BundledResources::CompileAndStoreService, feature_category: :pipeline_composition do
  let_it_be(:version, freeze: false) { create(:ci_catalog_resource_version, semver: 'v2.1.0-rc1') }
  let_it_be(:release_version, freeze: false) do
    create(:ci_catalog_resource_version, catalog_resource: version.catalog_resource,
      project: version.project, semver: 'v2.0.0')
  end

  let_it_be(:source_component) do
    create(:ci_catalog_resource_component, version: version, name: 'component',
      spec: { 'inputs' => { 'stage' => { 'default' => 'test' } } })
  end

  let(:compile_response) do
    ServiceResponse.success(payload: { components: [{ name: 'component', content: 'image: alpine' }] })
  end

  subject(:execute) { described_class.new(version).execute }

  before do
    [version, release_version].each do |resource_version|
      allow_next_instance_of(::Ci::Catalog::Resources::Bundle::CompileService, resource_version) do |service|
        allow(service).to receive(:execute).and_return(compile_response)
      end
    end
  end

  it 'compiles through CompileService rather than the compiler directly' do
    expect(::Gitlab::Ci::Catalog::Bundle::Compiler).not_to receive(:new)

    execute
  end

  context 'when compilation fails' do
    let(:compile_response) { ServiceResponse.error(message: 'Version has no publisher', reason: :missing_publisher) }

    it 'returns the compile error and stores nothing' do
      expect { execute }.not_to change { ::Ci::Catalog::BundledResource.count }

      expect(execute).to be_error
      expect(execute.reason).to eq(:missing_publisher)
    end
  end

  context 'when compilation succeeds' do
    it 'stores the bundled resource with a normalized natural key' do
      allow(::Gitlab.config.gitlab).to receive(:server_fqdn).and_return('GitLab.Example.Com')

      expect { execute }.to change { ::Ci::Catalog::BundledResource.count }.by(1)

      expect(::Ci::Catalog::BundledResource.last).to have_attributes(
        server_fqdn: 'gitlab.example.com',
        full_path: version.project.full_path.downcase
      )
    end

    it 'copies the version semver, including the prefix' do
      expect { execute }.to change { ::Ci::Catalog::BundledResources::Version.count }.by(1)

      bundled_version = ::Ci::Catalog::BundledResources::Version.last

      expect(bundled_version).to have_attributes(
        semver_major: 2, semver_minor: 1, semver_patch: 0,
        semver_prerelease: 'rc1', semver_prefixed: true,
        released_at: version.released_at
      )
      expect(bundled_version.semver.to_s).to eq('v2.1.0-rc1')
    end

    it 'returns the stored records to the caller' do
      expect(execute).to be_success
      expect(execute.payload.keys).to contain_exactly(:bundled_resource, :version, :components)
    end

    it 'copies the readme and stores it rendered' do
      allow(version).to receive(:readme).and_return('# Component readme')

      execute

      bundled_version = ::Ci::Catalog::BundledResources::Version.last

      expect(bundled_version.readme).to eq('# Component readme')
      expect(bundled_version.readme_html).to include('Component readme')
      expect(bundled_version.cached_markdown_version).to be_present
    end

    it 'stores each component with the published spec and the compiled document' do
      expect { execute }.to change { ::Ci::Catalog::BundledResources::Component.count }.by(1)

      component = ::Ci::Catalog::BundledResources::Component.last

      expect(component.name).to eq('component')
      expect(component.spec).to eq(source_component.spec)
      expect(component.file.read).to eq('image: alpine')
    end

    it 'writes the component to the object key derived from the bundled records' do
      execute

      component = ::Ci::Catalog::BundledResources::Component.last
      expected = ::Gitlab::Ci::Catalog::Bundle::ObjectKey.new(component)

      expect(component.file.path).to end_with(File.join(expected.dir, expected.filename))
    end

    it 'uploads the documents before opening a transaction' do
      baseline = ::ApplicationRecord.connection.open_transactions

      expect(::CarrierWaveStringFile).to receive(:new_file).and_wrap_original do |method, **args|
        expect(::ApplicationRecord.connection.open_transactions).to eq(baseline)

        method.call(**args)
      end

      execute
    end

    it 'does not move created_at when a component is bundled again' do
      execute

      component = ::Ci::Catalog::BundledResources::Component.last
      original = component.created_at

      travel_to(1.hour.from_now) { described_class.new(version).execute }

      expect(component.reload.created_at).to be_within(1.second).of(original)
    end

    it 'writes no rows when a document fails to upload' do
      allow_next_instance_of(::Ci::Catalog::BundledResources::Component) do |component|
        allow(component).to receive(:store_file!).and_raise(Errno::ECONNREFUSED)
      end

      expect { execute }.to raise_error(Errno::ECONNREFUSED)

      expect(::Ci::Catalog::BundledResource.count).to eq(0)
      expect(::Ci::Catalog::BundledResources::Version.count).to eq(0)
      expect(::Ci::Catalog::BundledResources::Component.count).to eq(0)
    end

    it 'sets latest_released_at from the latest version, ignoring prereleases' do
      execute

      resource = ::Ci::Catalog::BundledResource.last
      expect(resource.latest_released_at).to be_nil

      described_class.new(release_version).execute

      expect(resource.reload.latest_released_at).to be_within(1.second).of(release_version.released_at)

      described_class.new(version).execute

      expect(resource.reload.latest_released_at).to be_within(1.second).of(release_version.released_at)
    end

    context 'when a compiled component has no published spec' do
      let(:compile_response) do
        ServiceResponse.success(payload: { components: [{ name: 'orphan', content: 'image: alpine' }] })
      end

      it 'stores an empty spec and logs the discrepancy' do
        expect(::Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Bundled catalog component has no published spec',
            component_name: 'orphan'
          )
        )

        execute

        expect(::Ci::Catalog::BundledResources::Component.last.spec).to eq({})
      end
    end

    it 'is idempotent for the same version' do
      described_class.new(version).execute

      expect { execute }.not_to change {
        [::Ci::Catalog::BundledResource.count,
          ::Ci::Catalog::BundledResources::Version.count,
          ::Ci::Catalog::BundledResources::Component.count]
      }
    end
  end
end
