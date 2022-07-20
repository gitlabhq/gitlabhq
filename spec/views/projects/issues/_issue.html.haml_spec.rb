# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/issues/_issue.html.haml' do
  before do
    assign(:project, issue.project)
    assign(:issuable_meta_data, {
      issue.id => Gitlab::IssuableMetadata::IssuableMeta.new(1, 1, 1, 1)
    })

    render partial: 'projects/issues/issue', locals: { issue: issue }
  end

  describe 'timestamp', :freeze_time do
    context 'when issue is open' do
      let(:issue) { create(:issue, updated_at: 1.day.ago) }

      it 'shows last updated date' do
        expect(rendered).to have_content("updated #{format_timestamp(1.day.ago)}")
      end
    end

    context 'when issue is closed' do
      let(:issue) { create(:issue, :closed, closed_at: 2.days.ago, updated_at: 1.day.ago) }

      it 'shows closed date' do
        expect(rendered).to have_content("closed #{format_timestamp(2.days.ago)}")
      end
    end

    context 'when issue is closed but closed_at is empty' do
      let(:issue) { create(:issue, :closed, closed_at: nil, updated_at: 1.day.ago) }

      it 'shows last updated date' do
        expect(rendered).to have_content("updated #{format_timestamp(1.day.ago)}")
      end
    end

    def format_timestamp(time)
      l(time, format: "%b %d, %Y")
    end
  end
end
