require 'spec_helper'

module Gitlab::Markdown
  describe UserReferenceFilter do
    include ReferenceFilterSpecHelper

    let(:project) { create(:empty_project) }
    let(:user)    { create(:user) }

    it 'requires project context' do
      expect { described_class.call('Example @mention', {}) }.
        to raise_error(ArgumentError, /:project/)
    end

    it 'ignores invalid users' do
      exp = act = 'Hey @somebody'
      expect(filter(act).to_html).to eq(exp)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Hey @#{user.username}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    context 'mentioning @all' do
      before do
        project.team << [project.creator, :developer]
      end

      it 'supports a special @all mention' do
        doc = filter("Hey @all")
        expect(doc.css('a').length).to eq 1
        expect(doc.css('a').first.attr('href'))
          .to eq urls.namespace_project_url(project.namespace, project)
      end

      it 'adds to the results hash' do
        result = pipeline_result('Hey @all')
        expect(result[:references][:user]).to eq [project.creator]
      end
    end

    context 'mentioning a user' do
      let(:reference) { "@#{user.username}" }

      it 'links to a User' do
        doc = filter("Hey #{reference}")
        expect(doc.css('a').first.attr('href')).to eq urls.user_url(user)
      end

      # TODO (rspeicher): This test might be overkill
      it 'links to a User with a period' do
        user = create(:user, name: 'alphA.Beta')

        doc = filter("Hey @#{user.username}")
        expect(doc.css('a').length).to eq 1
      end

      # TODO (rspeicher): This test might be overkill
      it 'links to a User with an underscore' do
        user = create(:user, name: 'ping_pong_king')

        doc = filter("Hey @#{user.username}")
        expect(doc.css('a').length).to eq 1
      end

      it 'adds to the results hash' do
        result = pipeline_result("Hey #{reference}")
        expect(result[:references][:user]).to eq [user]
      end
    end

    context 'mentioning a group' do
      let(:group) { create(:group) }
      let(:user)  { create(:user) }

      let(:reference) { "@#{group.name}" }

      context 'that the current user can read' do
        before do
          group.add_user(user, Gitlab::Access::DEVELOPER)
        end

        it 'links to the Group' do
          doc = filter("Hey #{reference}", current_user: user)
          expect(doc.css('a').first.attr('href')).to eq urls.group_url(group)
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
      skip 'TODO (rspeicher): Re-enable when usernames can\'t end in periods.'
      doc = filter("Mention me (@#{user.username}.)")
      expect(doc.to_html).to match(/\(<a.+>@#{user.username}<\/a>\.\)/)
    end

    it 'includes default classes' do
      doc = filter("Hey @#{user.username}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-project_member'
    end

    it 'includes an optional custom class' do
      doc = filter("Hey @#{user.username}", reference_class: 'custom')
      expect(doc.css('a').first.attr('class')).to include 'custom'
    end

    it 'supports an :only_path context' do
      doc = filter("Hey @#{user.username}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq urls.user_path(user)
    end
  end
end
