# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::VirtualDomain, feature_category: :pages do
  describe '#certificate and #key pair' do
    let(:domain) { nil }
    let(:project) { instance_double(Project) }

    subject(:virtual_domain) { described_class.new(projects: [project], domain: domain) }

    it 'returns nil if there is no domain provided' do
      expect(virtual_domain.certificate).to be_nil
      expect(virtual_domain.key).to be_nil
    end

    context 'when Pages domain is provided' do
      let(:domain) { instance_double(PagesDomain, certificate: 'certificate', key: 'key') }

      it 'returns certificate and key from the provided domain' do
        expect(virtual_domain.certificate).to eq('certificate')
        expect(virtual_domain.key).to eq('key')
      end
    end
  end

  describe '#lookup_paths' do
    let(:domain) { nil }
    let(:trim_prefix) { nil }
    let(:project_a) { instance_double(Project) }
    let(:project_b) { instance_double(Project) }
    let(:project_c) { instance_double(Project) }
    let(:pages_lookup_path_a) { instance_double(Pages::LookupPath, prefix: 'aaa', source: { type: 'zip', path: 'https://example.com' }) }
    let(:pages_lookup_path_b) { instance_double(Pages::LookupPath, prefix: 'bbb', source: { type: 'zip', path: 'https://example.com' }) }
    let(:pages_lookup_path_without_source) { instance_double(Pages::LookupPath, prefix: 'ccc', source: nil) }

    subject(:virtual_domain) do
      described_class.new(projects: project_list, domain: domain, trim_prefix: trim_prefix)
    end

    before do
      allow(Pages::LookupPath)
        .to receive(:new)
        .with(project_a, domain: domain, trim_prefix: trim_prefix)
        .and_return(pages_lookup_path_a)

      allow(Pages::LookupPath)
        .to receive(:new)
        .with(project_b, domain: domain, trim_prefix: trim_prefix)
        .and_return(pages_lookup_path_b)

      allow(Pages::LookupPath)
        .to receive(:new)
        .with(project_c, domain: domain, trim_prefix: trim_prefix)
        .and_return(pages_lookup_path_without_source)
    end

    context 'when there is pages domain provided' do
      let(:domain) { instance_double(PagesDomain) }
      let(:project_list) { [project_a, project_b, project_c] }

      it 'returns collection of projects pages lookup paths sorted by prefix in reverse' do
        expect(virtual_domain.lookup_paths).to eq([pages_lookup_path_b, pages_lookup_path_a])
      end
    end

    context 'when there is trim_prefix provided' do
      let(:trim_prefix) { 'group/' }
      let(:project_list) { [project_a, project_b] }

      it 'returns collection of projects pages lookup paths sorted by prefix in reverse' do
        expect(virtual_domain.lookup_paths).to eq([pages_lookup_path_b, pages_lookup_path_a])
      end
    end
  end

  describe '#cache_key' do
    it 'returns the cache key based in the given cache_control' do
      cache_control = instance_double(::Gitlab::Pages::CacheControl, cache_key: 'cache_key')
      virtual_domain = described_class.new(projects: [instance_double(Project)], cache: cache_control)

      expect(virtual_domain.cache_key).to eq('cache_key')
    end

    it 'returns nil when no cache_control is given' do
      virtual_domain = described_class.new(projects: [instance_double(Project)])

      expect(virtual_domain.cache_key).to be_nil
    end
  end
end
