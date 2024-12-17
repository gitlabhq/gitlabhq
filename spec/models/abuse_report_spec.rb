# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReport, feature_category: :insider_threat do
  include Gitlab::Routing.url_helpers

  let_it_be(:report, reload: true) { create(:abuse_report) }
  let_it_be(:user, reload: true) { create(:admin) }

  subject { report }

  it { expect(subject).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:reporter).class_name('User').inverse_of(:reported_abuse_reports) }
    it { is_expected.to belong_to(:resolved_by).class_name('User').inverse_of(:resolved_abuse_reports) }
    it { is_expected.to belong_to(:user).inverse_of(:abuse_reports) }
    it { is_expected.to have_many(:events).class_name('ResourceEvents::AbuseReportEvent').inverse_of(:abuse_report) }
    it { is_expected.to have_many(:notes) }
    it { is_expected.to have_many(:user_mentions).class_name('AntiAbuse::Reports::UserMention') }
    it { is_expected.to have_many(:admin_abuse_report_assignees).class_name('Admin::AbuseReportAssignee') }
    it { is_expected.to have_many(:assignees).class_name('User').through(:admin_abuse_report_assignees) }

    it do
      is_expected.to have_many(:label_links).inverse_of(:abuse_report).class_name('AntiAbuse::Reports::LabelLink')
    end

    it do
      is_expected.to have_many(:labels).through(:label_links).source(:abuse_report_label)
        .class_name('AntiAbuse::Reports::Label')
    end

    it "aliases reporter to author" do
      expect(subject.author).to be(subject.reporter)
    end
  end

  describe 'validations' do
    let(:http)  { 'http://gitlab.com' }
    let(:https) { 'https://gitlab.com' }
    let(:ftp)   { 'ftp://example.com' }
    let(:javascript) { 'javascript:alert(window.opener.document.location)' }

    it { is_expected.to validate_presence_of(:reporter).on(:create) }
    it { is_expected.to validate_presence_of(:user).on(:create) }
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

    it { is_expected.to validate_length_of(:mitigation_steps).is_at_most(1000).allow_blank }

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

    describe 'evidence' do
      it { is_expected.not_to allow_value("string").for(:evidence) }
      it { is_expected.not_to allow_value(1.0).for(:evidence) }

      it { is_expected.to allow_value(nil).for(:evidence) }

      it {
        is_expected.to allow_value(
          {
            issues: [
              {
                id: 1,
                title: "test issue title",
                description: "test issue content"
              }
            ],
            snippets: [
              {
                id: 2,
                content: "snippet content"
              }
            ],
            notes: [
              {
                id: 44,
                content: "notes content"
              }
            ],
            user: {
              login_count: 1,
              account_age: 3,
              spam_score: 0.3,
              telesign_score: 0.4,
              arkos_score: 0.2,
              pvs_score: 0.8,
              product_coverage: 0.8,
              virus_total_score: 0.2
            }
          }).for(:evidence)
      }
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

    describe '.aggregated_by_user_and_category' do
      let_it_be(:report3) { create(:abuse_report, category: report1.category, user: report1.user) }
      let_it_be(:report4) { create(:abuse_report, category: 'phishing', user: report1.user) }
      let_it_be(:report5) { create(:abuse_report, category: report1.category, user: build(:user)) }

      let_it_be(:sort_by_count) { true }

      subject(:aggregated) { described_class.aggregated_by_user_and_category(sort_by_count) }

      context 'when sort_by_count = true' do
        it 'sorts by aggregated_count in descending order and created_at in descending order' do
          expect(aggregated).to eq([report1, report5, report4, report])
        end

        it 'returns count with aggregated reports' do
          expect(aggregated[0].count).to eq(2)
        end
      end

      context 'when sort_by_count = false' do
        let_it_be(:sort_by_count) { false }

        it 'does not sort using a specific order' do
          expect(aggregated).to match_array([report, report1, report4, report5])
        end
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

    subject(:report_type) { report.report_type }

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

    subject(:reported_content) { report.reported_content }

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

  describe '#past_closed_reports_for_user' do
    let(:report_1) { create(:abuse_report, :closed) }
    let(:report_2) { create(:abuse_report, user: report.user) }
    let(:report_3) { create(:abuse_report, :closed, user: report.user) }

    it 'returns past closed reports for the same user' do
      expect(report.past_closed_reports_for_user).to match_array(report_3)
    end
  end

  describe '#similar_open_reports_for_user' do
    let(:report_1) { create(:abuse_report, category: 'spam') }
    let(:report_2) { create(:abuse_report, category: 'spam', user: report.user) }
    let(:report_3) { create(:abuse_report, category: 'offensive', user: report.user) }
    let(:report_4) { create(:abuse_report, :closed, category: 'spam', user: report.user) }

    it 'returns open reports for the same user and category' do
      expect(report.similar_open_reports_for_user).to match_array(report_2)
    end

    it 'returns no abuse reports when the report is closed' do
      expect(report_4.similar_open_reports_for_user).to match_array(described_class.none)
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

  describe '#uploads_sharding_key' do
    it 'returns empty hash' do
      expect(report.uploads_sharding_key).to eq({})
    end
  end
end
