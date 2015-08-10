require 'spec_helper'

module Gitlab::Markdown
  describe UserReferenceFilter do
    include FilterSpecHelper

    let(:project)   { create(:empty_project) }
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
        result = pipeline_result("Hey #{reference}")
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

      it 'includes a data-user-id attribute' do
        doc = filter("Hey #{reference}")
        link = doc.css('a').first

        expect(link).to have_attribute('data-user-id')
        expect(link.attr('data-user-id')).to eq user.namespace.owner_id.to_s
      end

      it 'adds to the results hash' do
        result = pipeline_result("Hey #{reference}")
        expect(result[:references][:user]).to eq [user]
      end
    end

    context 'mentioning a group' do
      let(:group)     { create(:group) }
      let(:user)      { create(:user) }
      let(:reference) { group.to_reference }

      context 'that the current user can read' do
        before do
          group.add_developer(user)
        end

        it 'links to the Group' do
          doc = filter("Hey #{reference}", current_user: user)
          expect(doc.css('a').first.attr('href')).to eq urls.group_url(group)
        end

        it 'includes a data-group-id attribute' do
          doc = filter("Hey #{reference}", current_user: user)
          link = doc.css('a').first

          expect(link).to have_attribute('data-group-id')
          expect(link.attr('data-group-id')).to eq group.id.to_s
        end

        it 'adds to the results hash' do
          result = pipeline_result("Hey #{reference}", current_user: user)
          expect(result[:references][:user]).to eq group.users
        end
      end

      context 'that the current user cannot read' do
        it 'ignores references to the Group' do
          doc = filter("Hey #{reference}", current_user: user)
          expect(doc.to_html).to eq "Hey #{reference}"
        end

        it 'does not add to the results hash' do
          result = pipeline_result("Hey #{reference}", current_user: user)
          expect(result[:references][:user]).to eq []
        end
      end
    end

    it 'links with adjacent text' do
      skip "TODO (rspeicher): Re-enable when usernames can't end in periods."
      doc = filter("Mention me (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{reference}<\/a>\.\)/)
    end

    it 'includes default classes' do
      doc = filter("Hey #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-project_member'
    end

    it 'includes an optional custom class' do
      doc = filter("Hey #{reference}", reference_class: 'custom')
      expect(doc.css('a').first.attr('class')).to include 'custom'
    end

    it 'supports an :only_path context' do
      doc = filter("Hey #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq urls.user_path(user)
    end
  end
end
