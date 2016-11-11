require 'spec_helper'
require 'email_spec'

describe Notify, "merge request notifications" do
  include EmailSpec::Matchers

  describe "#resolved_all_discussions_email" do
    let(:user) { create(:user) }
    let(:merge_request) { create(:merge_request) }
    let(:current_user) { create(:user) }

    subject { Notify.resolved_all_discussions_email(user.id, merge_request.id, current_user.id) }

    it "includes the name of the resolver" do
      expect(subject).to have_body_text current_user.name
    end
  end
end
