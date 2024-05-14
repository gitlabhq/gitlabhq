# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_issue.html.haml', feature_category: :service_desk do
  before do
    assign(:project, issue.project)
    assign(:issuable_meta_data, {
      issue.id => Gitlab::IssuableMetadata::IssuableMeta.new(1, 1, 1, 1)
    })

    render partial: 'projects/issue', locals: { issue: issue }
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

    context 'when issue is service desk issue' do
      let_it_be(:email) { 'user@example.com' }
      let_it_be(:obfuscated_email) { 'us*****@e*****.c**' }
      let_it_be(:issue) { create(:issue, author: Users::Internal.support_bot, service_desk_reply_to: email) }

      context 'with anonymous user' do
        it 'obfuscates service_desk_reply_to email for anonymous user' do
          expect(rendered).to have_content(obfuscated_email)
        end
      end

      context 'with signed in user' do
        let_it_be(:user) { create(:user) }

        before do
          allow(view).to receive(:current_user).and_return(user)
          allow(view).to receive(:issue).and_return(issue)
        end

        context 'when user has no role in project' do
          it 'obfuscates service_desk_reply_to email' do
            render

            expect(rendered).to have_content(obfuscated_email)
          end
        end

        context 'when user has guest role in project' do
          before do
            issue.project.add_guest(user)
          end

          it 'obfuscates service_desk_reply_to email' do
            render

            expect(rendered).to have_content(obfuscated_email)
          end
        end

        context 'when user has (at least) reporter role in project' do
          before do
            issue.project.add_reporter(user)
          end

          it 'shows full service_desk_reply_to email' do
            render

            expect(rendered).to have_content(email)
          end
        end
      end
    end

    def format_timestamp(time)
      l(time, format: "%b %d, %Y")
    end
  end
end
