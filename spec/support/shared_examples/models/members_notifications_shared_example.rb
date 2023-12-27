# frozen_string_literal: true

RSpec.shared_examples 'members notifications' do |entity_type|
  let_it_be(:user) { create(:user) }

  let(:notification_service) { double('NotificationService').as_null_object }

  before do
    allow(member).to receive(:notification_service).and_return(notification_service)
  end

  describe "#after_create" do
    let(:member) { build(:"#{entity_type}_member", "#{entity_type}": create(entity_type.to_s), user: user) }

    it "sends email to user" do
      expect(notification_service).to receive(:"new_#{entity_type}_member").with(member)

      member.save!
    end
  end

  describe '#after_commit' do
    context 'on creation of a member requesting access' do
      let(:member) do
        build(:"#{entity_type}_member", :access_request, "#{entity_type}": create(entity_type.to_s), user: user)
      end

      it "calls NotificationService.new_access_request" do
        expect(notification_service).to receive(:new_access_request).with(member)

        member.save!
      end
    end
  end

  describe '#accept_request' do
    let(:member) { create(:"#{entity_type}_member", :access_request) }

    it "calls NotificationService.new_#{entity_type}_member" do
      expect(notification_service).to receive(:"new_#{entity_type}_member").with(member)

      member.accept_request(create(:user))
    end
  end

  describe "#accept_invite!" do
    let(:member) { create(:"#{entity_type}_member", :invited) }

    it "calls NotificationService.accept_#{entity_type}_invite" do
      expect(notification_service).to receive(:"accept_#{entity_type}_invite").with(member)

      member.accept_invite!(build(:user))
    end
  end

  describe "#decline_invite!" do
    let(:member) { create(:"#{entity_type}_member", :invited) }

    it "calls NotificationService.decline_#{entity_type}_invite" do
      expect(notification_service).to receive(:decline_invite).with(member)

      member.decline_invite!
    end
  end
end
