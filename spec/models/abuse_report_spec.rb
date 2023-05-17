# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReport, feature_category: :insider_threat do
  include Gitlab::Routing.url_helpers

  let_it_be(:report, reload: true) { create(:abuse_report) }
  let_it_be(:user, reload: true) { create(:admin) }

  subject { report }

  it { expect(subject).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:reporter).class_name('User') }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:events).class_name('ResourceEvents::AbuseReportEvent').inverse_of(:abuse_report) }

    it "aliases reporter to author" do
      expect(subject.author).to be(subject.reporter)
    end
  end

  describe 'validations' do
    let(:http)  { 'http://gitlab.com' }
    let(:https) { 'https://gitlab.com' }
    let(:ftp)   { 'ftp://example.com' }
    let(:javascript) { 'javascript:alert(window.opener.document.location)' }

    it { is_expected.to validate_presence_of(:reporter) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_presence_of(:category) }

    it do
      is_expected.to validate_uniqueness_of(:user_id)
        .scoped_to([:reporter_id, :category])
        .with_message('You have already reported this user')
    end

    it { is_expected.to validate_length_of(:reported_from_url).is_at_most(512).allow_blank }
    it { is_expected.to allow_value(http).for(:reported_from_url) }
    it { is_expected.to allow_value(https).for(:reported_from_url) }
    it { is_expected.not_to allow_value(ftp).for(:reported_from_url) }
    it { is_expected.not_to allow_value(javascript).for(:reported_from_url) }
    it { is_expected.to allow_value('http://localhost:9000').for(:reported_from_url) }
    it { is_expected.to allow_value('https://gitlab.com').for(:reported_from_url) }

    it { is_expected.to allow_value([]).for(:links_to_spam) }
    it { is_expected.to allow_value(nil).for(:links_to_spam) }
    it { is_expected.to allow_value('').for(:links_to_spam) }

    it { is_expected.to allow_value(['https://gitlab.com']).for(:links_to_spam) }
    it { is_expected.to allow_value(['http://localhost:9000']).for(:links_to_spam) }

    it { is_expected.not_to allow_value(['spam']).for(:links_to_spam) }
    it { is_expected.not_to allow_value(['http://localhost:9000', 'spam']).for(:links_to_spam) }

    it { is_expected.to allow_value(['https://gitlab.com'] * 20).for(:links_to_spam) }
    it { is_expected.not_to allow_value(['https://gitlab.com'] * 21).for(:links_to_spam) }

    it {
      is_expected.to allow_value([
        "https://gitlab.com/#{SecureRandom.alphanumeric(493)}"
      ]).for(:links_to_spam)
    }

    it {
      is_expected.not_to allow_value([
        "https://gitlab.com/#{SecureRandom.alphanumeric(494)}"
      ]).for(:links_to_spam)
    }

    context 'for screenshot' do
      let(:txt_file) { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }
      let(:img_file) { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }

      it { is_expected.not_to allow_value(txt_file).for(:screenshot) }
      it { is_expected.to allow_value(img_file).for(:screenshot) }

      it { is_expected.to allow_value(nil).for(:screenshot) }
      it { is_expected.to allow_value('').for(:screenshot) }
    end
  end

  describe 'scopes' do
    let_it_be(:reporter) { create(:user) }
    let_it_be(:report1) { create(:abuse_report, reporter: reporter) }
    let_it_be(:report2) { create(:abuse_report, :closed, category: 'phishing') }

    describe '.by_reporter_id' do
      subject(:results) { described_class.by_reporter_id(reporter.id) }

      it 'returns reports with reporter_id equal to the given user id' do
        expect(subject).to match_array([report1])
      end
    end

    describe '.open' do
      subject(:results) { described_class.open }

      it 'returns reports without resolved_at value' do
        expect(subject).to match_array([report, report1])
      end
    end

    describe '.closed' do
      subject(:results) { described_class.closed }

      it 'returns reports with resolved_at value' do
        expect(subject).to match_array([report2])
      end
    end

    describe '.by_category' do
      it 'returns abuse reports with the specified category' do
        expect(described_class.by_category('phishing')).to match_array([report2])
      end
    end
  end

  describe 'before_validation' do
    context 'when links to spam contains empty strings' do
      let(:report) { create(:abuse_report, links_to_spam: ['', 'https://gitlab.com']) }

      it 'removes empty strings' do
        expect(report.links_to_spam).to match_array(['https://gitlab.com'])
      end
    end
  end

  describe '#remove_user' do
    it 'blocks the user' do
      expect { subject.remove_user(deleted_by: user) }.to change { subject.user.blocked? }.to(true)
    end

    it 'lets a worker delete the user' do
      expect(DeleteUserWorker).to receive(:perform_async).with(user.id, subject.user.id, { hard_delete: true })

      subject.remove_user(deleted_by: user)
    end
  end

  describe '#notify' do
    it 'delivers' do
      expect(AbuseReportMailer).to receive(:notify).with(subject.id)
        .and_return(spy)

      subject.notify
    end

    it 'returns early when not persisted' do
      report = build(:abuse_report)

      expect(AbuseReportMailer).not_to receive(:notify)

      report.notify
    end
  end

  describe '#screenshot_path' do
    let(:report) { create(:abuse_report, :with_screenshot) }

    context 'with asset host configured' do
      let(:asset_host) { 'https://gitlab-assets.example.com' }

      before do
        allow(ActionController::Base).to receive(:asset_host) { asset_host }
      end

      it 'returns a full URL with the asset host and system path' do
        expect(report.screenshot_path).to eq("#{asset_host}#{report.screenshot.url}")
      end
    end

    context 'when no asset path configured' do
      let(:base_url) { Gitlab.config.gitlab.base_url }

      it 'returns a full URL with the base url and system path' do
        expect(report.screenshot_path).to eq("#{base_url}#{report.screenshot.url}")
      end
    end
  end

  describe '#report_type' do
    let(:report) { build_stubbed(:abuse_report, reported_from_url: url) }
    let_it_be(:issue) { create(:issue) }
    let_it_be(:merge_request) { create(:merge_request) }
    let_it_be(:user) { create(:user) }

    subject { report.report_type }

    context 'when reported from an issue' do
      let(:url) { project_issue_url(issue.project, issue) }

      it { is_expected.to eq :issue }
    end

    context 'when reported from a merge request' do
      let(:url) { project_merge_request_url(merge_request.project, merge_request) }

      it { is_expected.to eq :merge_request }
    end

    context 'when reported from a profile' do
      let(:url) { user_url(user) }

      it { is_expected.to eq :profile }
    end

    describe 'comment type' do
      context 'when reported from an issue comment' do
        let(:url) { project_issue_url(issue.project, issue, anchor: 'note_123') }

        it { is_expected.to eq :comment }
      end

      context 'when reported from a merge request comment' do
        let(:url) { project_merge_request_url(merge_request.project, merge_request, anchor: 'note_123') }

        it { is_expected.to eq :comment }
      end

      context 'when anchor exists not from an issue or merge request URL' do
        let(:url) { user_url(user, anchor: 'note_123') }

        it { is_expected.to eq :profile }
      end

      context 'when note id is invalid' do
        let(:url) { project_merge_request_url(merge_request.project, merge_request, anchor: 'note_12x') }

        it { is_expected.to eq :merge_request }
      end
    end

    context 'when URL cannot be matched' do
      let(:url) { '/xxx' }

      it { is_expected.to be_nil }
    end
  end

  describe '#reported_content' do
    let(:report) { build_stubbed(:abuse_report, reported_from_url: url) }
    let_it_be(:issue) { create(:issue, description: 'issue description') }
    let_it_be(:merge_request) { create(:merge_request, description: 'mr description') }
    let_it_be(:user) { create(:user) }

    subject { report.reported_content }

    context 'when reported from an issue' do
      let(:url) { project_issue_url(issue.project, issue) }

      it { is_expected.to eq issue.description_html }
    end

    context 'when reported from a merge request' do
      let(:url) { project_merge_request_url(merge_request.project, merge_request) }

      it { is_expected.to eq merge_request.description_html }
    end

    context 'when reported from a merge request with an invalid note ID' do
      let(:url) do
        "#{project_merge_request_url(merge_request.project, merge_request)}#note_[]"
      end

      it { is_expected.to eq merge_request.description_html }
    end

    context 'when reported from a profile' do
      let(:url) { user_url(user) }

      it { is_expected.to be_nil }
    end

    context 'when reported from an unknown URL' do
      let(:url) { '/xxx' }

      it { is_expected.to be_nil }
    end

    context 'when reported from an invalid URL' do
      let(:url) { 'http://example.com/[]' }

      it { is_expected.to be_nil }
    end

    context 'when reported from an issue comment' do
      let(:note) { create(:note, noteable: issue, project: issue.project, note: 'comment in issue') }
      let(:url) { project_issue_url(issue.project, issue, anchor: "note_#{note.id}") }

      it { is_expected.to eq note.note_html }
    end

    context 'when reported from a merge request comment' do
      let(:note) { create(:note, noteable: merge_request, project: merge_request.project, note: 'comment in mr') }
      let(:url) { project_merge_request_url(merge_request.project, merge_request, anchor: "note_#{note.id}") }

      it { is_expected.to eq note.note_html }
    end

    context 'when report type cannot be determined, because the comment does not exist' do
      let(:url) do
        project_merge_request_url(merge_request.project, merge_request, anchor: "note_#{non_existing_record_id}")
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#other_reports_for_user' do
    let(:report) { create(:abuse_report) }
    let(:another_user_report) { create(:abuse_report, user: report.user) }
    let(:another_report) { create(:abuse_report) }

    it 'returns other reports for the same user' do
      expect(report.other_reports_for_user).to match_array(another_user_report)
    end
  end

  describe 'enums' do
    let(:categories) do
      {
        spam: 1,
        offensive: 2,
        phishing: 3,
        crypto: 4,
        credentials: 5,
        copyright: 6,
        malware: 7,
        other: 8
      }
    end

    it { is_expected.to define_enum_for(:category).with_values(**categories) }
  end
end
