# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Ewm do
  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }
      it { is_expected.to validate_presence_of(:new_issue_url) }

      it_behaves_like 'issue tracker integration URL attribute', :project_url
      it_behaves_like 'issue tracker integration URL attribute', :issues_url
      it_behaves_like 'issue tracker integration URL attribute', :new_issue_url
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
      it { is_expected.not_to validate_presence_of(:new_issue_url) }
    end
  end

  describe "ReferencePatternValidation" do
    it "extracts bug" do
      expect(subject.reference_pattern.match("This is bug 123")[:issue]).to eq("bug 123")
    end

    it "extracts task" do
      expect(subject.reference_pattern.match("This is task 123.")[:issue]).to eq("task 123")
    end

    it "extracts work item" do
      expect(subject.reference_pattern.match("This is work item 123 now")[:issue]).to eq("work item 123")
    end

    it "extracts work item" do
      expect(subject.reference_pattern.match("workitem 123 at the beginning")[:issue]).to eq("workitem 123")
    end

    it "extracts defect" do
      expect(subject.reference_pattern.match("This is defect 123 defect")[:issue]).to eq("defect 123")
    end

    it "extracts rtcwi" do
      expect(subject.reference_pattern.match("This is rtcwi 123")[:issue]).to eq("rtcwi 123")
    end
  end

  describe '#issue_url' do
    context 'when issues_url is configured' do
      before do
        subject.issues_url = 'https://example.com/issues/:id'
      end

      it 'returns the URL with the issue ID substituted' do
        expect(subject.issue_url('bug 123')).to eq('https://example.com/issues/123')
      end
    end

    context 'when issues_url is nil' do
      before do
        subject.issues_url = nil
      end

      it 'returns nil' do
        expect(subject.issue_url('bug 123')).to be_nil
      end
    end
  end
end
