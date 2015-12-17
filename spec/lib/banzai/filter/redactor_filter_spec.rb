require 'spec_helper'

describe Banzai::Filter::RedactorFilter, lib: true do
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

  context 'with data-project' do
    it 'removes unpermitted Project references' do
      user = create(:user)
      project = create(:empty_project)

      link = reference_link(project: project.id, reference_filter: 'ReferenceFilter')
      doc = filter(link, current_user: user)

      expect(doc.css('a').length).to eq 0
    end

    it 'allows permitted Project references' do
      user = create(:user)
      project = create(:empty_project)
      project.team << [user, :master]

      link = reference_link(project: project.id, reference_filter: 'ReferenceFilter')
      doc = filter(link, current_user: user)

      expect(doc.css('a').length).to eq 1
    end

    it 'handles invalid Project references' do
      link = reference_link(project: 12345, reference_filter: 'ReferenceFilter')

      expect { filter(link) }.not_to raise_error
    end
  end

  context "for user references" do

    context 'with data-group' do
      it 'removes unpermitted Group references' do
        user = create(:user)
        group = create(:group)

        link = reference_link(group: group.id, reference_filter: 'UserReferenceFilter')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
      end

      it 'allows permitted Group references' do
        user = create(:user)
        group = create(:group)
        group.add_developer(user)

        link = reference_link(group: group.id, reference_filter: 'UserReferenceFilter')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end

      it 'handles invalid Group references' do
        link = reference_link(group: 12345, reference_filter: 'UserReferenceFilter')

        expect { filter(link) }.not_to raise_error
      end
    end

    context 'with data-user' do
      it 'allows any User reference' do
        user = create(:user)

        link = reference_link(user: user.id, reference_filter: 'UserReferenceFilter')
        doc = filter(link)

        expect(doc.css('a').length).to eq 1
      end
    end
  end
end
