require 'spec_helper'

describe Mattermost::Team do
  describe '#all' do
    let(:user) { build(:user) }

    subject { described_class.new(user) }

    let(:response) do
      [{
        "id" => "xiyro8huptfhdndadpz8r3wnbo",
        "create_at" => 1482174222155,
        "update_at" => 1482174222155,
        "delete_at" => 0,
        "display_name" => "chatops",
        "name" => "chatops",
        "email" => "admin@example.com",
        "type" => "O",
        "company_name" => "",
        "allowed_domains" => "",
        "invite_id" => "o4utakb9jtb7imctdfzbf9r5ro",
        "allow_open_invite" => false }]
    end


    before do
      allow(subject).to receive(:json_get).and_return(response)
    end

    it 'gets the teams' do
      expect(subject.all.count).to be(1)
    end
  end
end
