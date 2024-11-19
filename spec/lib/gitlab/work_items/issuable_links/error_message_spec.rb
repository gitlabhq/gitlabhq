# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::WorkItems::IssuableLinks::ErrorMessage, feature_category: :team_planning do
  let(:target_type) { 'issue' }
  let(:container_type) { 'project' }
  let(:error_message) { described_class.new(target_type: target_type, container_type: container_type) }

  describe '#for_http_status' do
    context 'when status is 404' do
      it 'returns the not found message' do
        expect(error_message.for_http_status(404)).to eq(error_message.not_found)
      end
    end

    context 'when status is 403' do
      it 'returns the no permission message' do
        expect(error_message.for_http_status(403)).to eq(error_message.no_permission_error)
      end
    end

    context 'when status is 409' do
      it 'returns the already assigned message' do
        expect(error_message.for_http_status(409)).to eq(error_message.already_assigned)
      end
    end

    context 'when status is not recognized' do
      it 'returns nil' do
        expect(error_message.for_http_status(500)).to be_nil
      end
    end
  end

  describe '#already_assigned' do
    it 'returns the correct message' do
      expect(error_message.already_assigned).to eq('Issue(s) already assigned')
    end
  end

  describe '#no_permission_error' do
    it 'returns the correct message' do
      expect(error_message.no_permission_error).to eq(
        "Couldn't link issues. You must have at least the Guest role in both issue's projects."
      )
    end

    context 'when container_type is group' do
      let(:container_type) { 'group' }

      it 'pluralizes group correctly' do
        expect(error_message.no_permission_error).to eq(
          "Couldn't link issues. You must have at least the Guest role in both issue's groups."
        )
      end
    end
  end

  describe '#not_found' do
    it 'returns the correct message' do
      expect(error_message.not_found).to eq(
        'No matching issue found. Make sure that you are adding a valid issue URL.'
      )
    end
  end

  context 'with different target_type' do
    let(:target_type) { 'merge request' }

    it 'uses the correct target type in messages' do
      expect(error_message.not_found).to eq(
        'No matching merge request found. Make sure that you are adding a valid merge request URL.'
      )
    end
  end
end
