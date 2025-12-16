# frozen_string_literal: true

RSpec.shared_examples 'members notifications' do |entity_type|
  let_it_be(:user) { create(:user) }

  describe '#accept_request' do
    let(:member) { create(:"#{entity_type}_member", :access_request) }

    it "sends access granted notification" do
      expect(Members::AccessGrantedMailer).to receive_message_chain(:with, :email, :deliver_later)

      member.accept_request(create(:user))
    end
  end
end
