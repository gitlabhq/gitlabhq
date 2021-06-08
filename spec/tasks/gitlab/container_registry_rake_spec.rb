# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:container_registry namespace rake tasks', :silence_stdout do
  let_it_be(:api_url) { 'http://registry.gitlab' }

  before :all do
    Rake.application.rake_require 'tasks/gitlab/container_registry'
  end

  describe '#configure' do
    subject { run_rake_task('gitlab:container_registry:configure') }

    shared_examples 'invalid config' do
      it 'does not call UpdateContainerRegistryInfoService' do
        expect_any_instance_of(UpdateContainerRegistryInfoService).not_to receive(:execute)

        subject
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end

      it 'prints a warning message' do
        expect { subject }.to output("Registry is not enabled or registry api url is not present.\n").to_stdout
      end
    end

    context 'when container registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it_behaves_like 'invalid config'
    end

    context 'when container registry api_url is blank' do
      before do
        stub_container_registry_config(api_url: '')
      end

      it_behaves_like 'invalid config'
    end

    context 'when container registry is enabled and api_url is not blank' do
      before do
        stub_container_registry_config(enabled: true, api_url: api_url)
      end

      it 'calls UpdateContainerRegistryInfoService' do
        expect_next_instance_of(UpdateContainerRegistryInfoService) do |service|
          expect(service).to receive(:execute)
        end

        subject
      end
    end
  end
end
