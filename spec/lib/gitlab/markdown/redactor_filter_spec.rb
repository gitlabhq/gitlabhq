require 'spec_helper'

module Gitlab::Markdown
  describe RedactorFilter do
    include ActionView::Helpers::UrlHelper
    include FilterSpecHelper

    it 'ignores non-GFM links' do
      html = %(See <a href="https://google.com/">Google</a>)
      doc = filter(html, current_user: double)

      expect(doc.css('a').length).to eq 1
    end

    def reference_link(data)
      link_to('text', '', class: 'gfm', data: data)
    end

    context 'with data-group-id' do
      it 'removes unpermitted Group references' do
        user = create(:user)
        group = create(:group)

        link = reference_link(group_id: group.id)
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
      end

      it 'allows permitted Group references' do
        user = create(:user)
        group = create(:group)
        group.add_developer(user)

        link = reference_link(group_id: group.id)
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end

      it 'handles invalid Group references' do
        link = reference_link(group_id: 12345)

        expect { filter(link) }.not_to raise_error
      end
    end

    context 'with data-project-id' do
      it 'removes unpermitted Project references' do
        user = create(:user)
        project = create(:empty_project)

        link = reference_link(project_id: project.id)
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
      end

      it 'allows permitted Project references' do
        user = create(:user)
        project = create(:empty_project)
        project.team << [user, :master]

        link = reference_link(project_id: project.id)
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end

      it 'handles invalid Project references' do
        link = reference_link(project_id: 12345)

        expect { filter(link) }.not_to raise_error
      end
    end

    context 'with data-user-id' do
      it 'allows any User reference' do
        user = create(:user)

        link = reference_link(user_id: user.id)
        doc = filter(link)

        expect(doc.css('a').length).to eq 1
      end
    end
  end
end
