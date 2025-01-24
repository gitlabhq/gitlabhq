# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::CustomIssueTracker do
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
end
