# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ide::BaseConfigService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:sha) { 'sha' }

  describe '#execute' do
    subject { described_class.new(project, user, sha: sha).execute }

    context 'when insufficient permission' do
      it 'returns an error' do
        is_expected.to include(
          status: :error,
          message: 'Insufficient permissions to read configuration')
      end
    end

    context 'for developer' do
      before do
        project.add_developer(user)
      end

      context 'when file is missing' do
        it 'returns an error' do
          is_expected.to include(
            status: :error,
            message: "Failed to load Web IDE config file '.gitlab/.gitlab-webide.yml' for sha")
        end
      end

      context 'when file is present' do
        before do
          allow(project.repository).to receive(:blob_data_at).with('sha', anything) do
            config_content
          end
        end

        context 'content is not valid' do
          let(:config_content) { 'invalid content' }

          it 'returns an error' do
            is_expected.to include(
              status: :error,
              message: "Invalid configuration format")
          end
        end
      end
    end
  end
end
