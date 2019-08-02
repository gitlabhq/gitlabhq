require 'spec_helper'

describe 'shared/_label_row.html.haml' do
  label_types = {
    'project label': :label,
    'group label': :group_label
  }

  label_types.each do |label_type, label_factory|
    let!(:label) do
      label_record = create(label_factory)
      label_record.present(issuable_subject: label_record.subject)
    end

    context "for a #{label_type}" do
      before do
        if label.project_label?
          @project = label.project
        else
          @group = label.group
        end
      end

      it 'has a non-linked label title' do
        render 'shared/label_row', label: label

        expect(rendered).not_to have_css('a', text: label.title)
      end

      it "has Issues link for #{label_type}" do
        render 'shared/label_row', label: label

        expect(rendered).to have_css('a', text: 'Issues')
      end

      it "has Merge request link for #{label_type}" do
        render 'shared/label_row', label: label

        expect(rendered).to have_css('a', text: 'Merge requests')
      end
    end
  end
end
