require 'spec_helper'

describe Banzai::Filter::UserReferenceFilter, lib: true do
  include FilterSpecHelper

  let(:project)   { create(:empty_project, :public) }
  let(:user)      { create(:user) }
  let(:reference) { user.to_reference }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  it 'ignores invalid users' do
    exp = act = "Hey #{invalidate_reference(reference)}"
    expect(reference_filter(act).to_html).to eq(exp)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Hey #{reference}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'mentioning @all' do
    let(:reference) { User.reference_prefix + 'all' }

    before do
      project.team << [project.creator, :developer]
    end

    it 'supports a special @all mention' do
      doc = reference_filter("Hey #{reference}", author: user)
      expect(doc.css('a').length).to eq 1
      expect(doc.css('a').first.attr('href'))
        .to eq urls.namespace_project_url(project.namespace, project)
    end

    it 'includes a data-author attribute when there is an author' do
      doc = reference_filter(reference, author: user)

      expect(doc.css('a').first.attr('data-author')).to eq(user.id.to_s)
    end

    it 'does not include a data-author attribute when there is no author' do
      doc = reference_filter(reference)

      expect(doc.css('a').first.has_attribute?('data-author')).to eq(false)
    end
  end

  context 'mentioning a user' do
    it 'links to a User' do
      doc = reference_filter("Hey #{reference}")
      expect(doc.css('a').first.attr('href')).to eq urls.user_url(user)
    end

    it 'links to a User with a period' do
      user = create(:user, name: 'alphA.Beta')

      doc = reference_filter("Hey #{user.to_reference}")
      expect(doc.css('a').length).to eq 1
    end

    it 'links to a User with an underscore' do
      user = create(:user, name: 'ping_pong_king')

      doc = reference_filter("Hey #{user.to_reference}")
      expect(doc.css('a').length).to eq 1
    end

    it 'includes a data-user attribute' do
      doc = reference_filter("Hey #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-user')
      expect(link.attr('data-user')).to eq user.namespace.owner_id.to_s
    end
  end

  context 'mentioning a group' do
    let(:group)     { create(:group) }
    let(:reference) { group.to_reference }

    it 'links to the Group' do
      doc = reference_filter("Hey #{reference}")
      expect(doc.css('a').first.attr('href')).to eq urls.group_url(group)
    end

    it 'includes a data-group attribute' do
      doc = reference_filter("Hey #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-group')
      expect(link.attr('data-group')).to eq group.id.to_s
    end
  end

  it 'links with adjacent text' do
    doc = reference_filter("Mention me (#{reference}.)")
    expect(doc.to_html).to match(/\(<a.+>#{reference}<\/a>\.\)/)
  end

  it 'includes default classes' do
    doc = reference_filter("Hey #{reference}")
    expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-project_member has-tooltip'
  end

  it 'supports an :only_path context' do
    doc = reference_filter("Hey #{reference}", only_path: true)
    link = doc.css('a').first.attr('href')

    expect(link).not_to match %r(https?://)
    expect(link).to eq urls.user_path(user)
  end

  context 'referencing a user in a link href' do
    let(:reference) { %Q{<a href="#{user.to_reference}">User</a>} }

    it 'links to a User' do
      doc = reference_filter("Hey #{reference}")
      expect(doc.css('a').first.attr('href')).to eq urls.user_url(user)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Mention me (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>User<\/a>\.\)/)
    end

    it 'includes a data-user attribute' do
      doc = reference_filter("Hey #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-user')
      expect(link.attr('data-user')).to eq user.namespace.owner_id.to_s
    end
  end

  describe '#namespaces' do
    it 'returns a Hash containing all Namespaces' do
      document = Nokogiri::HTML.fragment("<p>#{user.to_reference}</p>")
      filter = described_class.new(document, project: project)
      ns = user.namespace

      expect(filter.namespaces).to eq({ ns.path => ns })
    end
  end

  describe '#usernames' do
    it 'returns the usernames mentioned in a document' do
      document = Nokogiri::HTML.fragment("<p>#{user.to_reference}</p>")
      filter = described_class.new(document, project: project)

      expect(filter.usernames).to eq([user.username])
    end
  end
end
