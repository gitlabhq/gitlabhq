# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::VirtualHostFinder, feature_category: :pages do
  let_it_be(:project) { create(:project) }

  before_all do
    project.update_pages_deployment!(create(:pages_deployment, project: project))
  end

  it 'returns nil when host is empty' do
    expect(described_class.new(nil).execute).to be_nil
    expect(described_class.new('').execute).to be_nil
  end

  context 'when host is a pages custom domain host' do
    let_it_be(:pages_domain) { create(:pages_domain, project: project) }

    subject(:virtual_domain) { described_class.new(pages_domain.domain).execute }

    context 'when there are no pages deployed for the project' do
      before_all do
        project.mark_pages_as_not_deployed
      end

      it 'returns nil' do
        expect(virtual_domain).to be_nil
      end
    end

    context 'when there are pages deployed for the project' do
      before_all do
        project.mark_pages_as_deployed
      end

      it 'returns the virual domain when there are pages deployed for the project' do
        expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
        expect(virtual_domain.cache_key).to match(/pages_domain_for_domain_#{pages_domain.id}_/)
        expect(virtual_domain.lookup_paths.length).to eq(1)
        expect(virtual_domain.lookup_paths.first.project_id).to eq(project.id)
      end

      context 'when :cache_pages_domain_api is disabled' do
        before do
          stub_feature_flags(cache_pages_domain_api: false)
        end

        it 'returns the virual domain when there are pages deployed for the project' do
          expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
          expect(virtual_domain.cache_key).to be_nil
          expect(virtual_domain.lookup_paths.length).to eq(1)
          expect(virtual_domain.lookup_paths.first.project_id).to eq(project.id)
        end
      end
    end
  end

  context 'when host is a namespace domain' do
    context 'when there are no pages deployed for the project' do
      before_all do
        project.mark_pages_as_not_deployed
      end

      it 'returns no result if the provided host is not subdomain of the Pages host' do
        virtual_domain = described_class.new("#{project.namespace.path}.something.io").execute

        expect(virtual_domain).to eq(nil)
      end

      it 'returns the virual domain with no lookup_paths' do
        virtual_domain = described_class.new("#{project.namespace.path}.#{Settings.pages.host}").execute

        expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
        expect(virtual_domain.cache_key).to match(/pages_domain_for_namespace_#{project.namespace.id}_/)
        expect(virtual_domain.lookup_paths.length).to eq(0)
      end

      context 'when :cache_pages_domain_api is disabled' do
        before do
          stub_feature_flags(cache_pages_domain_api: false)
        end

        it 'returns the virual domain with no lookup_paths' do
          virtual_domain = described_class.new("#{project.namespace.path}.#{Settings.pages.host}".downcase).execute

          expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
          expect(virtual_domain.cache_key).to be_nil
          expect(virtual_domain.lookup_paths.length).to eq(0)
        end
      end
    end

    context 'when there are pages deployed for the project' do
      before_all do
        project.mark_pages_as_deployed
        project.namespace.update!(path: 'topNAMEspace')
      end

      it 'returns no result if the provided host is not subdomain of the Pages host' do
        virtual_domain = described_class.new("#{project.namespace.path}.something.io").execute

        expect(virtual_domain).to eq(nil)
      end

      it 'returns the virual domain when there are pages deployed for the project' do
        virtual_domain = described_class.new("#{project.namespace.path}.#{Settings.pages.host}").execute

        expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
        expect(virtual_domain.cache_key).to match(/pages_domain_for_namespace_#{project.namespace.id}_/)
        expect(virtual_domain.lookup_paths.length).to eq(1)
        expect(virtual_domain.lookup_paths.first.project_id).to eq(project.id)
      end

      it 'finds domain with case-insensitive' do
        virtual_domain = described_class.new("#{project.namespace.path}.#{Settings.pages.host.upcase}").execute

        expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
        expect(virtual_domain.cache_key).to match(/pages_domain_for_namespace_#{project.namespace.id}_/)
        expect(virtual_domain.lookup_paths.length).to eq(1)
        expect(virtual_domain.lookup_paths.first.project_id).to eq(project.id)
      end

      context 'when :cache_pages_domain_api is disabled' do
        before_all do
          stub_feature_flags(cache_pages_domain_api: false)
        end

        it 'returns the virual domain when there are pages deployed for the project' do
          virtual_domain = described_class.new("#{project.namespace.path}.#{Settings.pages.host}").execute

          expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
          expect(virtual_domain.cache_key).to be_nil
          expect(virtual_domain.lookup_paths.length).to eq(1)
          expect(virtual_domain.lookup_paths.first.project_id).to eq(project.id)
        end
      end
    end
  end

  context 'when host is a unique domain' do
    before_all do
      project.project_setting.update!(pages_unique_domain: 'unique-domain')
    end

    subject(:virtual_domain) { described_class.new("unique-domain.#{Settings.pages.host.upcase}").execute }

    context 'when pages unique domain is enabled' do
      before_all do
        project.project_setting.update!(pages_unique_domain_enabled: true)
      end

      context 'when there are no pages deployed for the project' do
        before_all do
          project.mark_pages_as_not_deployed
        end

        it 'returns nil' do
          expect(virtual_domain).to be_nil
        end
      end

      context 'when there are pages deployed for the project' do
        before_all do
          project.mark_pages_as_deployed
        end

        it 'returns the virual domain when there are pages deployed for the project' do
          expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
          expect(virtual_domain.lookup_paths.length).to eq(1)
          expect(virtual_domain.lookup_paths.first.project_id).to eq(project.id)
        end

        context 'when :cache_pages_domain_api is disabled' do
          before do
            stub_feature_flags(cache_pages_domain_api: false)
          end

          it 'returns the virual domain when there are pages deployed for the project' do
            expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
            expect(virtual_domain.lookup_paths.length).to eq(1)
            expect(virtual_domain.lookup_paths.first.project_id).to eq(project.id)
          end
        end
      end
    end

    context 'when pages unique domain is disabled' do
      before_all do
        project.project_setting.update!(pages_unique_domain_enabled: false)
      end

      context 'when there are no pages deployed for the project' do
        before_all do
          project.mark_pages_as_not_deployed
        end

        it 'returns nil' do
          expect(virtual_domain).to be_nil
        end
      end

      context 'when there are pages deployed for the project' do
        before_all do
          project.mark_pages_as_deployed
        end

        it 'returns nil' do
          expect(virtual_domain).to be_nil
        end
      end
    end
  end
end
