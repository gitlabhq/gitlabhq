# frozen_string_literal: true

RSpec.shared_examples 'issuable entity current_user properties' do
  describe 'can_create_confidential_note' do
    subject do
      described_class.new(resource, request: request)
        .as_json[:current_user][:can_create_confidential_note]
    end

    context 'when user can create confidential notes' do
      before do
        resource.resource_parent.add_reporter(user)
      end

      it { is_expected.to be(true) }
    end

    context 'when user cannot create confidential notes' do
      it { is_expected.to eq(false) }
    end
  end
end
