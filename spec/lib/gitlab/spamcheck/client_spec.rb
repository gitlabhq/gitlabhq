# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Spamcheck::Client do
  include_context 'includes Spam constants'

  let(:endpoint) { 'grpc://grpc.test.url' }
  let_it_be(:user) { create(:user, organization: 'GitLab') }
  let(:verdict_value) { ::Spamcheck::SpamVerdict::Verdict::ALLOW }
  let(:error_value) { "" }

  let(:attribs_value) do
    extra_attributes = Google::Protobuf::Map.new(:string, :string)
    extra_attributes["monitorMode"] = "false"
    extra_attributes
  end

  let_it_be(:issue) { create(:issue, description: 'Test issue description') }

  let(:response) do
    verdict = ::Spamcheck::SpamVerdict.new
    verdict.verdict = verdict_value
    verdict.error = error_value
    verdict.extra_attributes = attribs_value
    verdict
  end

  subject { described_class.new.issue_spam?(spam_issue: issue, user: user) }

  before do
    stub_application_setting(spam_check_endpoint_url: endpoint)
  end

  describe '#issue_spam?' do
    before do
      allow_next_instance_of(::Spamcheck::SpamcheckService::Stub) do |instance|
        allow(instance).to receive(:check_for_spam_issue).and_return(response)
      end
    end

    using RSpec::Parameterized::TableSyntax

    where(:verdict, :expected) do
      ::Spamcheck::SpamVerdict::Verdict::ALLOW                | Spam::SpamConstants::ALLOW
      ::Spamcheck::SpamVerdict::Verdict::CONDITIONAL_ALLOW    | Spam::SpamConstants::CONDITIONAL_ALLOW
      ::Spamcheck::SpamVerdict::Verdict::DISALLOW             | Spam::SpamConstants::DISALLOW
      ::Spamcheck::SpamVerdict::Verdict::BLOCK                | Spam::SpamConstants::BLOCK_USER
      ::Spamcheck::SpamVerdict::Verdict::NOOP                 | Spam::SpamConstants::NOOP
    end

    with_them do
      let(:verdict_value) { verdict }

      it "returns expected spam constant" do
        expect(subject).to eq([expected, { "monitorMode" => "false" }, ""])
      end
    end

    it 'includes interceptors' do
      expect_next_instance_of(::Gitlab::Spamcheck::Client) do |client|
        expect(client).to receive(:interceptors).and_call_original
      end
      subject
    end
  end

  describe "#build_issue_protobuf", :aggregate_failures do
    it 'builds the expected protobuf object' do
      cxt = { action: :create }
      issue_pb = described_class.new.send(:build_issue_protobuf,
                                          issue: issue, user: user,
                                          context: cxt)
      expect(issue_pb.title).to eq issue.title
      expect(issue_pb.description).to eq issue.description
      expect(issue_pb.user_in_project). to be false
      expect(issue_pb.project.project_id).to eq issue.project_id
      expect(issue_pb.created_at).to eq timestamp_to_protobuf_timestamp(issue.created_at)
      expect(issue_pb.updated_at).to eq timestamp_to_protobuf_timestamp(issue.updated_at)
      expect(issue_pb.action).to be ::Spamcheck::Action.lookup(::Spamcheck::Action::CREATE)
      expect(issue_pb.user.username).to eq user.username
    end
  end

  describe '#build_user_proto_buf', :aggregate_failures do
    it 'builds the expected protobuf object' do
      user_pb = described_class.new.send(:build_user_protobuf, user)
      expect(user_pb.username).to eq user.username
      expect(user_pb.org).to eq user.organization
      expect(user_pb.created_at).to eq timestamp_to_protobuf_timestamp(user.created_at)
      expect(user_pb.emails.count).to be 1
      expect(user_pb.emails.first.email).to eq user.email
      expect(user_pb.emails.first.verified).to eq user.confirmed?
    end

    context 'when user has multiple email addresses' do
      let(:secondary_email) {create(:email, :confirmed, user: user)}

      before do
        user.emails << secondary_email
      end

      it 'adds emails to the user pb object' do
        user_pb = described_class.new.send(:build_user_protobuf, user)
        expect(user_pb.emails.count).to eq 2
        expect(user_pb.emails.first.email).to eq user.email
        expect(user_pb.emails.first.verified).to eq user.confirmed?
        expect(user_pb.emails.last.email).to eq secondary_email.email
        expect(user_pb.emails.last.verified).to eq secondary_email.confirmed?
      end
    end
  end

  describe "#build_project_protobuf", :aggregate_failures do
    it 'builds the expected protobuf object' do
      project_pb = described_class.new.send(:build_project_protobuf, issue)
      expect(project_pb.project_id).to eq issue.project_id
      expect(project_pb.project_path).to eq issue.project.full_path
    end
  end

  private

  def timestamp_to_protobuf_timestamp(timestamp)
    Google::Protobuf::Timestamp.new(seconds: timestamp.to_time.to_i,
                                    nanos: timestamp.to_time.nsec)
  end
end
