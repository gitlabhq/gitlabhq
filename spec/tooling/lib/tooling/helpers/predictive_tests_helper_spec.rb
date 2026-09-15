# frozen_string_literal: true

require 'tempfile'
require_relative '../../../../../tooling/lib/tooling/helpers/predictive_tests_helper'

class MockClass # rubocop:disable Gitlab/NamespacedClass
  include Tooling::Helpers::PredictiveTestsHelper
end

RSpec.describe Tooling::Helpers::PredictiveTestsHelper, feature_category: :tooling do
  let(:instance) { MockClass.new }

  describe '#folders_for_available_editions' do
    let(:base_folder_path) { 'app/views' }

    subject { instance.folders_for_available_editions(base_folder_path) }

    context 'when FOSS' do
      before do
        allow(GitlabEdition).to receive_messages(ee?: false, jh?: false)
      end

      it 'returns the correct paths' do
        expect(subject).to match_array([base_folder_path])
      end
    end

    context 'when EE' do
      before do
        allow(GitlabEdition).to receive_messages(ee?: true, jh?: false)
      end

      it 'returns the correct paths' do
        expect(subject).to match_array([base_folder_path, "ee/#{base_folder_path}"])
      end
    end

    context 'when JiHu' do
      before do
        allow(GitlabEdition).to receive_messages(ee?: true, jh?: true)
      end

      it 'returns the correct paths' do
        expect(subject).to match_array([base_folder_path, "ee/#{base_folder_path}", "jh/#{base_folder_path}"])
      end
    end
  end
end
