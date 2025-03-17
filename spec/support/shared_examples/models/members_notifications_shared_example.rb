# frozen_string_literal: true

RSpec.shared_examples 'members notifications' do |entity_type|
  let_it_be(:user) { create(:user) }

  let(:notification_service) { double('NotificationService').as_null_object }

  before do
    allow(member).to receive(:notification_service).and_return(notification_service)
  end

  describe '#accept_request' do
    let(:member) { create(:"#{entity_type}_member", :access_request) }

    it "calls NotificationService.new_member" do
      expect(notification_service).to receive(:new_member).with(member)

      member.accept_request(create(:user))
    end
  end
end
