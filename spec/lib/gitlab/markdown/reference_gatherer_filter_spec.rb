require 'spec_helper'

module Gitlab::Markdown
  describe ReferenceGathererFilter do
    include ActionView::Helpers::UrlHelper
    include FilterSpecHelper

    def reference_link(data)
      link_to('text', '', class: 'gfm', data: data)
    end

    context "for issue references" do

      context 'with data-project' do
        it 'removes unpermitted Project references' do
          user = create(:user)
          project = create(:empty_project)
          issue = create(:issue, project: project)

          link = reference_link(project: project.id, issue: issue.id, reference_filter: Gitlab::Markdown::IssueReferenceFilter.name)
          result = pipeline_result(link, current_user: user)

          expect(result[:references][:issue]).to be_empty
        end

        it 'allows permitted Project references' do
          user = create(:user)
          project = create(:empty_project)
          issue = create(:issue, project: project)
          project.team << [user, :master]

          link = reference_link(project: project.id, issue: issue.id, reference_filter: Gitlab::Markdown::IssueReferenceFilter.name)
          result = pipeline_result(link, current_user: user)

          expect(result[:references][:issue]).to eq([issue])
        end

        it 'handles invalid Project references' do
          link = reference_link(project: 12345, issue: 12345, reference_filter: Gitlab::Markdown::IssueReferenceFilter.name)

          expect { pipeline_result(link) }.not_to raise_error
        end
      end
    end

    context "for user references" do

      context 'with data-group' do
        it 'removes unpermitted Group references' do
          user = create(:user)
          group = create(:group)

          link = reference_link(group: group.id, reference_filter: Gitlab::Markdown::UserReferenceFilter.name)
          result = pipeline_result(link, current_user: user)

          expect(result[:references][:user]).to be_empty
        end

        it 'allows permitted Group references' do
          user = create(:user)
          group = create(:group)
          group.add_developer(user)

          link = reference_link(group: group.id, reference_filter: Gitlab::Markdown::UserReferenceFilter.name)
          result = pipeline_result(link, current_user: user)

          expect(result[:references][:user]).to eq([user])
        end

        it 'handles invalid Group references' do
          link = reference_link(group: 12345, reference_filter: Gitlab::Markdown::UserReferenceFilter.name)

          expect { pipeline_result(link) }.not_to raise_error
        end
      end

      context 'with data-user' do
        it 'allows any User reference' do
          user = create(:user)

          link = reference_link(user: user.id, reference_filter: Gitlab::Markdown::UserReferenceFilter.name)
          result = pipeline_result(link)

          expect(result[:references][:user]).to eq([user])
        end
      end
    end
  end
end
