# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::UserReferenceFilter, feature_category: :markdown do
  include FilterSpecHelper

  def get_reference(user)
    user.to_reference
  end

  let(:project)   { create(:project, :public) }
  let(:user)      { create(:user) }
  subject { user }

  let(:subject_name) { "user" }
  let(:reference) { get_reference(user) }

  it_behaves_like 'user reference or project reference'

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  it 'ignores invalid users' do
    act = "Hey #{invalidate_reference(reference)}"
    expect(reference_filter(act).to_html).to include act
  end

  it 'ignores references with text before the @ sign' do
    act = "Hey foo#{reference}"
    expect(reference_filter(act).to_html).to include act
  end

  %w[pre code a style].each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      act = "<#{elem}>Hey #{reference}</#{elem}>"
      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'when `disable_all_mention` FF is enabled' do
    let(:reference) { User.reference_prefix + 'all' }

    context 'mentioning @all' do
      before do
        stub_feature_flags(disable_all_mention: true)

        project.add_developer(project.creator)
      end

      it 'ignores reference to @all' do
        doc = reference_filter("Hey #{reference}", author: project.creator)

        expect(doc.css('a').length).to eq 0
      end
    end
  end

  context 'mentioning @all (when `disable_all_mention` FF is disabled)' do
    let(:reference) { User.reference_prefix + 'all' }

    before do
      stub_feature_flags(disable_all_mention: false)

      project.add_developer(project.creator)
    end

    it_behaves_like 'a reference containing an element node'

    it 'supports a special @all mention' do
      project.add_developer(user)
      doc = reference_filter("Hey #{reference}", author: user)

      expect(doc.css('a').length).to eq 1
      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_url(project)
    end

    it 'includes a data-author attribute when there is an author' do
      project.add_developer(user)
      doc = reference_filter(reference, author: user)

      expect(doc.css('a').first.attr('data-author')).to eq(user.id.to_s)
    end

    it 'does not include a data-author attribute when there is no author' do
      doc = reference_filter(reference)

      expect(doc.css('a').first.has_attribute?('data-author')).to eq(false)
    end

    it 'ignores reference to all when the user is not a project member' do
      doc = reference_filter("Hey #{reference}", author: user)

      expect(doc.css('a').length).to eq 0
    end
  end

  context 'mentioning a group' do
    let(:reference) { group.to_reference }
    let(:group)     { create(:group) }

    it_behaves_like 'a reference containing an element node'

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

  context 'mentioning a nested group' do
    let(:reference) { group.to_reference }
    let(:group)     { create(:group, :nested) }

    it_behaves_like 'a reference containing an element node'

    it 'links to the nested group' do
      doc = reference_filter("Hey #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.group_url(group)
    end

    it 'has the full group name as a title' do
      doc = reference_filter("Hey #{reference}")

      expect(doc.css('a').first.attr('title')).to eq group.full_name
    end
  end

  it 'links with adjacent text' do
    doc = reference_filter("Mention me (#{reference}.)")
    expect(doc.to_html).to match(%r{\(<a.+>#{reference}</a>\.\)})
  end

  it 'includes default classes' do
    doc = reference_filter("Hey #{reference}")
    expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-project_member js-user-link'
  end

  context 'when a project is not specified' do
    let(:project) { nil }

    it 'does not link a User' do
      doc = reference_filter("Hey #{reference}")

      expect(doc).not_to include('a')
    end

    context 'when skip_project_check set to true' do
      it 'links to a User' do
        doc = reference_filter("Hey #{reference}", skip_project_check: true)

        expect(doc.css('a').first.attr('href')).to eq urls.user_url(user)
      end

      it 'does not link users using @all reference' do
        doc = reference_filter("Hey #{User.reference_prefix}all", skip_project_check: true)

        expect(doc).not_to include('a')
      end
    end
  end

  context 'in group context' do
    let(:group) { create(:group) }
    let(:group_member) { create(:user) }

    before do
      group.add_developer(group_member)
    end

    let(:context) { { author: group_member, project: nil, group: group } }

    it 'supports a special @all mention' do
      stub_feature_flags(disable_all_mention: false)
      reference = User.reference_prefix + 'all'
      doc = reference_filter("Hey #{reference}", context)

      expect(doc.css('a').length).to eq(1)
      expect(doc.css('a').first.attr('href')).to eq urls.group_url(group)
    end

    it 'supports mentioning a single user' do
      reference = get_reference(group_member)
      doc = reference_filter("Hey #{reference}", context)

      expect(doc.css('a').first.attr('href')).to eq urls.user_url(group_member)
    end

    it 'supports mentioning a group' do
      reference = group.to_reference
      doc = reference_filter("Hey #{reference}", context)

      expect(doc.css('a').first.attr('href')).to eq urls.user_url(group)
    end
  end

  describe '#namespaces' do
    it 'returns a Hash containing all Namespaces' do
      document = Nokogiri::HTML.fragment("<p>#{get_reference(user)}</p>")
      filter = described_class.new(document, project: project)
      ns = user.namespace

      expect(filter.send(:namespaces)).to eq({ ns.path => ns })
    end
  end

  describe '#usernames' do
    it 'returns the usernames mentioned in a document' do
      document = Nokogiri::HTML.fragment("<p>#{get_reference(user)}</p>")
      filter = described_class.new(document, project: project)

      expect(filter.send(:usernames)).to eq([user.username])
    end
  end

  context 'checking N+1' do
    let(:user2)      { create(:user) }
    let(:group)      { create(:group) }
    let(:reference2) { user2.to_reference }
    let(:reference3) { group.to_reference }

    it 'does not have N+1 per multiple user references', :use_sql_query_cache do
      markdown = reference.to_s
      reference_filter(markdown) # warm up

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        reference_filter(markdown)
      end

      markdown = "#{reference} @qwertyuiopzx @wertyuio @ertyu @rtyui #{reference2} #{reference3}"

      expect do
        reference_filter(markdown)
      end.to issue_same_number_of_queries_as(control_count)
    end
  end

  it_behaves_like 'limits the number of filtered items' do
    let(:text) { "#{reference} #{reference} #{reference}" }
    let(:ends_with) { "</a> #{reference}" }
  end
end
