# frozen_string_literal: true

RSpec.shared_examples 'actor key validations' do
  context 'key id is not provided' do
    let(:key_id) { nil }

    it 'returns an error message' do
      subject

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq('Could not find a user without a key')
    end
  end

  context 'key does not exist' do
    let(:key_id) { non_existing_record_id }

    it 'returns an error message' do
      subject

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq('Could not find the given key')
    end
  end

  context 'key without user' do
    let(:key_id) { create(:key, user: nil).id }

    it 'returns an error message' do
      subject

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq('Could not find a user for the given key')
    end
  end
end
