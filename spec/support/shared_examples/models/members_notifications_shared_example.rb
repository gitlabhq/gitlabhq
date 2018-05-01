RSpec.shared_examples 'members notifications' do |entity_type|
  let(:notification_service) { double('NotificationService').as_null_object }

  before do
    allow(member).to receive(:notification_service).and_return(notification_service)
  end

  describe "#after_create" do
    let(:member) { build(:"#{entity_type}_member") }

    it "sends email to user" do
      expect(notification_service).to receive(:"new_#{entity_type}_member").with(member)

      member.save
    end
  end

  describe "#after_update" do
    let(:member) { create(:"#{entity_type}_member", :developer) }

    it "calls NotificationService.update_#{entity_type}_member" do
      expect(notification_service).to receive(:"update_#{entity_type}_member").with(member)

      member.update_attribute(:access_level, Member::MASTER)
    end

    it "does not send an email when the access level has not changed" do
      expect(notification_service).not_to receive(:"update_#{entity_type}_member")

      member.touch
    end
  end

  describe '#accept_request' do
    let(:member) { create(:"#{entity_type}_member", :access_request) }

    it "calls NotificationService.new_#{entity_type}_member" do
      expect(notification_service).to receive(:"new_#{entity_type}_member").with(member)

      member.accept_request
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
      expect(notification_service).to receive(:"decline_#{entity_type}_invite").with(member)

      member.decline_invite!
    end
  end
end
