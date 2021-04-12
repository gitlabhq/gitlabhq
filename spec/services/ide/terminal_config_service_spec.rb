# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ide::TerminalConfigService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:sha) { 'sha' }

  describe '#execute' do
    subject { described_class.new(project, user, sha: sha).execute }

    before do
      project.add_developer(user)

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

    context 'terminal not defined' do
      let(:config_content) { '{}' }

      it 'returns success' do
        is_expected.to include(
          status: :success,
          terminal: nil)
      end
    end

    context 'terminal enabled' do
      let(:config_content) { 'terminal: {}' }

      it 'returns success' do
        is_expected.to include(
          status: :success,
          terminal: {
            tag_list: [],
            yaml_variables: [],
            job_variables: [],
            options: { script: ["sleep 60"] }
          })
      end
    end

    context 'custom terminal enabled' do
      let(:config_content) { 'terminal: { before_script: [ls] }' }

      it 'returns success' do
        is_expected.to include(
          status: :success,
          terminal: {
            tag_list: [],
            yaml_variables: [],
            job_variables: [],
            options: { before_script: ["ls"], script: ["sleep 60"] }
          })
      end
    end
  end
end
