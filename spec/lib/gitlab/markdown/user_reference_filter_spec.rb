require 'spec_helper'

module Gitlab::Markdown
  describe UserReferenceFilter do
    include FilterSpecHelper

    let(:project)   { create(:empty_project, :public) }
    let(:user)      { create(:user) }
    let(:reference) { user.to_reference }

    it 'requires project context' do
      expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
    end

    it 'ignores invalid users' do
      exp = act = "Hey #{invalidate_reference(reference)}"
      expect(filter(act).to_html).to eq(exp)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Hey #{reference}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    context 'mentioning @all' do
      let(:reference) { User.reference_prefix + 'all' }

      before do
        project.team << [project.creator, :developer]
      end

      it 'supports a special @all mention' do
        doc = filter("Hey #{reference}")
        expect(doc.css('a').length).to eq 1
        expect(doc.css('a').first.attr('href'))
          .to eq urls.namespace_project_url(project.namespace, project)
      end

      it 'adds to the results hash' do
        result = reference_pipeline_result("Hey #{reference}")
        expect(result[:references][:user]).to eq [project.creator]
      end
    end

    context 'mentioning a user' do
      it 'links to a User' do
        doc = filter("Hey #{reference}")
        expect(doc.css('a').first.attr('href')).to eq urls.user_url(user)
      end

      it 'links to a User with a period' do
        user = create(:user, name: 'alphA.Beta')

        doc = filter("Hey #{user.to_reference}")
        expect(doc.css('a').length).to eq 1
      end

      it 'links to a User with an underscore' do
        user = create(:user, name: 'ping_pong_king')

        doc = filter("Hey #{user.to_reference}")
        expect(doc.css('a').length).to eq 1
      end

      it 'includes a data-user attribute' do
        doc = filter("Hey #{reference}")
        link = doc.css('a').first

        expect(link).to have_attribute('data-user')
        expect(link.attr('data-user')).to eq user.namespace.owner_id.to_s
      end

      it 'adds to the results hash' do
        result = reference_pipeline_result("Hey #{reference}")
        expect(result[:references][:user]).to eq [user]
      end
    end

    context 'mentioning a group' do
      let(:group)     { create(:group) }
      let(:reference) { group.to_reference }

      it 'links to the Group' do
        doc = filter("Hey #{reference}")
        expect(doc.css('a').first.attr('href')).to eq urls.group_url(group)
      end

      it 'includes a data-group attribute' do
        doc = filter("Hey #{reference}")
        link = doc.css('a').first

        expect(link).to have_attribute('data-group')
        expect(link.attr('data-group')).to eq group.id.to_s
      end

      it 'adds to the results hash' do
        result = reference_pipeline_result("Hey #{reference}")
        expect(result[:references][:user]).to eq group.users
      end
    end

    it 'links with adjacent text' do
      doc = filter("Mention me (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{reference}<\/a>\.\)/)
    end

    it 'includes default classes' do
      doc = filter("Hey #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-project_member'
    end

    it 'supports an :only_path context' do
      doc = filter("Hey #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq urls.user_path(user)
    end
  end
end
