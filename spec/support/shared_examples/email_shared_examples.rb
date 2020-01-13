# frozen_string_literal: true

shared_examples_for 'correctly finds the mail key' do
  specify do
    expect(Gitlab::Email::Handler).to receive(:for).with(an_instance_of(Mail::Message), 'gitlabhq/gitlabhq+auth_token').and_return(handler)

    receiver.execute
  end
end
