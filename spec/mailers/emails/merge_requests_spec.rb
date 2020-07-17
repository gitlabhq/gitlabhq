# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::MergeRequests do
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

  describe "#merge_when_pipeline_succeeds_email" do
    let(:user) { create(:user) }
    let(:merge_request) { create(:merge_request) }
    let(:current_user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:title) { "Merge request #{merge_request.to_reference} was scheduled to merge after pipeline succeeds by #{current_user.name}" }

    subject { Notify.merge_when_pipeline_succeeds_email(user.id, merge_request.id, current_user.id) }

    it "has required details" do
      expect(subject).to have_content title
      expect(subject).to have_content merge_request.to_reference
      expect(subject).to have_content current_user.name
    end
  end
end
