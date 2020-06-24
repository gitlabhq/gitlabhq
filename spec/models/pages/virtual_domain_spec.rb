# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::VirtualDomain do
  describe '#certificate and #key pair' do
    let(:domain) { nil }
    let(:project) { instance_double(Project) }

    subject(:virtual_domain) { described_class.new([project], domain: domain) }

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
    let(:project_a) { instance_double(Project) }
    let(:project_z) { instance_double(Project) }
    let(:pages_lookup_path_a) { instance_double(Pages::LookupPath, prefix: 'aaa') }
    let(:pages_lookup_path_z) { instance_double(Pages::LookupPath, prefix: 'zzz') }

    context 'when there is pages domain provided' do
      let(:domain) { instance_double(PagesDomain) }

      subject(:virtual_domain) { described_class.new([project_a, project_z], domain: domain) }

      it 'returns collection of projects pages lookup paths sorted by prefix in reverse' do
        expect(project_a).to receive(:pages_lookup_path).with(domain: domain, trim_prefix: nil).and_return(pages_lookup_path_a)
        expect(project_z).to receive(:pages_lookup_path).with(domain: domain, trim_prefix: nil).and_return(pages_lookup_path_z)

        expect(virtual_domain.lookup_paths).to eq([pages_lookup_path_z, pages_lookup_path_a])
      end
    end

    context 'when there is trim_prefix provided' do
      subject(:virtual_domain) { described_class.new([project_a, project_z], trim_prefix: 'group/') }

      it 'returns collection of projects pages lookup paths sorted by prefix in reverse' do
        expect(project_a).to receive(:pages_lookup_path).with(trim_prefix: 'group/', domain: nil).and_return(pages_lookup_path_a)
        expect(project_z).to receive(:pages_lookup_path).with(trim_prefix: 'group/', domain: nil).and_return(pages_lookup_path_z)

        expect(virtual_domain.lookup_paths).to eq([pages_lookup_path_z, pages_lookup_path_a])
      end
    end
  end
end
