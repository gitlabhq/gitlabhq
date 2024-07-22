# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Component, feature_category: :pipeline_composition do
  let_it_be(:context_project) { create(:project, :repository) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project_variables) { project.predefined_variables }

  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }
  let(:external_resource) { described_class.new(params, context) }
  let(:params) { { component: 'gitlab.com/acme/components/my-component@1.0.0' } }
  let(:fetch_service) { instance_double(::Ci::Components::FetchService) }

  let(:context_params) do
    {
      project: context_project,
      sha: 'context_sha',
      user: user,
      variables: project_variables
    }
  end

  let(:content) do
    <<~COMPONENT
    job:
      script: echo
    COMPONENT
  end

  let(:response) do
    ServiceResponse.success(payload: {
      content: content,
      path: 'templates/my_component.yml',
      project: project,
      sha: 'my_component_sha',
      name: 'my_component'
    })
  end

  before do
    allow(::Ci::Components::FetchService)
      .to receive(:new)
      .with(
        address: params[:component],
        current_user: context.user
      ).and_return(fetch_service)

    allow(fetch_service).to receive(:execute).and_return(response)
  end

  describe '#matching?' do
    subject(:matching) { external_resource.matching? }

    context 'when component is specified' do
      let(:params) { { component: 'some-value' } }

      it { is_expected.to be_truthy }
    end

    context 'when component is not specified' do
      let(:params) { { local: 'some-value' } }

      it { is_expected.to be_falsy }
    end
  end

  describe '#valid?' do
    subject(:valid?) do
      Gitlab::Ci::Config::External::Mapper::Verifier.new(context).process([external_resource])
      external_resource.valid?
    end

    context 'when the context project does not have a repository' do
      before do
        allow(context_project).to receive(:repository).and_return(nil)
      end

      it 'is invalid' do
        expect(subject).to be_falsy
        expect(external_resource.error_message).to eq('Unable to use components outside of a project context')
      end
    end

    context 'when location is not provided' do
      let(:params) { { component: 123 } }

      it 'is invalid' do
        expect(subject).to be_falsy
        expect(external_resource.error_message).to eq('Included file `123` needs to be a string')
      end
    end

    context 'when component path is provided' do
      context 'when component is not found' do
        let(:response) do
          ServiceResponse.error(message: 'Content not found')
        end

        it 'is invalid' do
          expect(subject).to be_falsy
          expect(external_resource.error_message).to eq('Content not found')
        end
      end

      context 'when component is found' do
        it 'is valid' do
          expect(subject).to be_truthy
          expect(external_resource.content).to eq(content)
        end

        context 'when content is not a valid YAML' do
          let(:content) { 'the-content' }

          it 'is invalid' do
            expect(subject).to be_falsy
            expect(external_resource.error_message).to match(/Invalid configuration format/)
          end
        end
      end
    end
  end

  describe '#content' do
    context 'when component is valid' do
      it 'tracks the event' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with('cicd_component_usage',
          values: external_resource.context.user.id)

        external_resource.content
      end

      context 'when user is missing in a context' do
        let_it_be(:user) { nil }

        it 'does not track the event' do
          expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

          external_resource.content
        end
      end
    end

    context 'when component is invalid' do
      let(:response) do
        ServiceResponse.error(message: 'Content not found')
      end

      it 'does not track the event' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        external_resource.content
      end
    end
  end

  describe '#metadata' do
    subject(:metadata) { external_resource.metadata }

    it 'returns the metadata' do
      is_expected.to include(
        context_project: context_project.full_path,
        context_sha: context.sha,
        type: :component,
        location: 'gitlab.com/acme/components/my-component@1.0.0',
        blob: a_string_ending_with("#{project.full_path}/-/blob/my_component_sha/templates/my_component.yml"),
        raw: nil,
        extra: {},
        component: {
          project: project,
          sha: 'my_component_sha',
          name: 'my_component'
        }
      )
    end
  end

  describe '#expand_context' do
    subject { external_resource.send(:expand_context_attrs) }

    it 'inherits user and variables while changes project and sha' do
      is_expected.to include(
        project: project,
        sha: 'my_component_sha',
        user: context.user,
        variables: context.variables)
    end
  end

  describe '#to_hash' do
    context 'when interpolation is being used' do
      let(:content) do
        <<~YAML
          spec:
            inputs:
              env:
          ---
          deploy:
            script: deploy $[[ inputs.env ]]
        YAML
      end

      let(:params) do
        { component: 'gitlab.com/acme/components/my-component@1.0', with: { env: 'production' } }
      end

      it 'correctly interpolates the content' do
        expect(external_resource.to_hash).to eq({ deploy: { script: 'deploy production' } })
      end
    end
  end

  describe '#load_and_validate_expanded_hash!' do
    let(:logger) { instance_double(::Gitlab::Ci::Pipeline::Logger, :instrument) }

    let(:context_params) do
      {
        project: context_project,
        sha: 'context_sha',
        user: user,
        variables: project_variables,
        logger: logger
      }
    end

    it 'tracks the content load time' do
      expect(logger).to receive(:instrument).once.ordered.with(:config_component_fetch_content_hash).and_yield
      expect(logger).to receive(:instrument).once.ordered.with(:config_file_fetch_content_hash).and_yield
      expect(logger).to receive(:instrument).once.ordered.with(:config_file_expand_content_includes).and_yield

      external_resource.load_and_validate_expanded_hash!
    end
  end
end
