require 'spec_helper'

describe 'shared/issuable/_approvals.html.haml' do
  let(:user) { create(:user) }
  let(:project) { build(:empty_project) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:form) { double('form') }

  before do
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    allow(form).to receive(:label)
    allow(form).to receive(:number_field)
    allow(merge_request).to receive(:requires_approve?).and_return(true)
    assign(:project, project)
    assign(:suggested_approvers, [])
  end

  context 'has no approvers' do
    it 'shows empty approvers list' do
      render 'shared/issuable/approvals', form: form, issuable: merge_request

      expect(rendered).to have_text('There are no approvers')
    end

    context 'can override approvers' do
      before do
        render 'shared/issuable/approvals', form: form, issuable: merge_request
      end

      it 'shows suggested approvers' do
        expect(rendered).to have_css('.suggested-approvers')
      end

      it 'shows select approvers field' do
        expect(rendered).to have_css('#merge_request_approver_ids')
      end

      it 'shows select approver groups field' do
        expect(rendered).to have_css('#merge_request_approver_group_ids')
      end
    end

    context 'can not override approvers' do
      before do
        allow(view).to receive(:can?).with(user, :update_approvers, merge_request).and_return(false)
        render 'shared/issuable/approvals', form: form, issuable: merge_request
      end

      it 'hides suggested approvers' do
        expect(rendered).not_to have_css('.suggested-approvers')
      end

      it 'hides select approvers field' do
        expect(rendered).not_to have_css('#merge_request_approver_ids')
      end

      it 'hides select approver groups field' do
        expect(rendered).not_to have_css('#merge_request_approver_group_ids')
      end
    end
  end

  context 'has approvers' do
    let(:user) { create(:user) }
    let(:approver) { create(:approver, user: user, target: merge_request) }
    let(:approver_group) { create(:approver_group, target: merge_request) }

    before do
      assign(:approver, approver)
      assign(:approver_group, approver_group)
    end

    it 'shows approver in table' do
      render 'shared/issuable/approvals', form: form, issuable: merge_request, project: project

      expect(rendered).to have_text(approver[:name])
      expect(rendered).to have_text(approver_group[:name])
    end

    context 'can override approvers' do
      it 'shows remove button for approver' do
        render 'shared/issuable/approvals', form: form, issuable: merge_request

        expect(rendered).to have_css('.btn-remove')
      end
    end

    context 'can not override approvers' do
      it 'hides remove button' do
        allow(view).to receive(:can?).with(user, :update_approvers, merge_request).and_return(false)

        render 'shared/issuable/approvals', form: form, issuable: merge_request

        expect(rendered).not_to have_css('.btn-remove')
      end
    end
  end
end
