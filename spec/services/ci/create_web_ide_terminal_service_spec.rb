# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreateWebIdeTerminalService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :small_repo, create_tag: 'v1.0.0') }
  let_it_be(:user) { create(:user) }

  let(:ref) { 'master' }

  describe '#execute' do
    subject { described_class.new(project, user, ref: ref).execute }

    context 'error handling' do
      shared_examples 'having an error' do |message|
        it 'returns an error' do
          is_expected.to eq(
            status: :error,
            message: message
          )
        end
      end

      shared_examples 'having insufficient permissions' do
        it_behaves_like 'having an error', 'Insufficient permissions to create a terminal'
      end

      context 'when user is developer' do
        before_all do
          project.add_developer(user)
        end

        it_behaves_like 'having insufficient permissions'
      end

      context 'when user is maintainer' do
        before_all do
          project.add_maintainer(user)
        end

        context 'when terminal is already running' do
          let!(:webide_pipeline) { create(:ci_pipeline, :webide, :running, project: project, user: user) }

          it_behaves_like 'having an error', 'There is already a terminal running'
        end

        context 'when ref is non-existing' do
          let(:ref) { 'non-existing-ref' }

          it_behaves_like 'having an error', 'Ref does not exist'
        end

        context 'when ref is a tag' do
          let(:ref) { 'v1.0.0' }

          it_behaves_like 'having an error', 'Ref needs to be a branch'
        end

        context 'when webide config is present' do
          before do
            stub_webide_config_file(config_content)
          end

          context 'config has invalid content' do
            let(:config_content) { 'invalid' }

            it_behaves_like 'having an error', 'Invalid configuration format'
          end

          context 'config is valid, but does not have terminal' do
            let(:config_content) { '{}' }

            it_behaves_like 'having an error', 'Terminal is not configured'
          end
        end
      end
    end
  end
end
