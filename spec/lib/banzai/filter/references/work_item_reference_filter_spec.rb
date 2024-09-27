# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::WorkItemReferenceFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:group)           { create(:group) }
  let_it_be(:namespace)       { create(:namespace, name: 'main-namespace') }
  let_it_be(:project)         { create(:project, :public, namespace: namespace, path: 'main-project') }
  let_it_be(:cross_namespace) { create(:namespace, name: 'cross-namespace') }
  let_it_be(:cross_project)   { create(:project, :public, namespace: cross_namespace, path: 'cross-project') }
  let_it_be(:work_item)       { create(:work_item, project: project) }

  def item_url(item)
    work_item_path = if item.project_id.present?
                       "/#{item.project.namespace.path}/#{item.project.path}/-/work_items/#{item.iid}"
                     else
                       "/groups/#{item.namespace.path}/-/work_items/#{item.iid}"
                     end

    "http://#{Gitlab.config.gitlab.host}#{work_item_path}"
  end

  it 'subclasses from IssueReferenceFilter' do
    expect(described_class.superclass).to eq Banzai::Filter::References::IssueReferenceFilter
  end

  shared_examples 'a reference with work item type information' do
    it 'contains work-item-type as a data attribute' do
      doc = reference_filter("Fixed #{reference}")

      expect(doc.css('a').first.attr('data-work-item-type')).to eq('issue')
    end
  end

  shared_examples 'a work item reference' do
    it_behaves_like 'a reference containing an element node'

    it_behaves_like 'a reference with work item type information'

    it 'links to a valid reference' do
      doc = reference_filter("Fixed #{written_reference}")

      expect(doc.css('a').first.attr('href')).to eq work_item_url
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{written_reference}.)")

      expect(doc.text).to match(%r{^Fixed \(.*\.\)})
    end

    it 'includes a title attribute' do
      doc = reference_filter("Issue #{written_reference}")

      expect(doc.css('a').first.attr('title')).to eq work_item.title
    end

    it 'escapes the title attribute' do
      work_item.update_attribute(:title, %("></a>whatever<a title="))

      doc = reference_filter("Issue #{written_reference}")

      expect(doc.text).not_to include 'whatever'
    end

    it 'renders non-HTML tooltips' do
      doc = reference_filter("Issue #{written_reference}")

      expect(doc.at_css('a')).not_to have_attribute('data-html')
    end

    it 'includes default classes' do
      doc = reference_filter("Issue #{written_reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-work_item'
    end

    it 'includes a data-issue attribute' do
      doc = reference_filter("See #{written_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-work-item')
      expect(link.attr('data-work-item')).to eq work_item.id.to_s
    end

    it 'includes a data-original attribute' do
      doc = reference_filter("See #{written_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-original')
      expect(link.attr('data-original')).to eq inner_text
    end

    it 'does not escape the data-original attribute' do
      skip if written_reference.start_with?('<a')

      inner_html = 'element <code>node</code> inside'
      doc = reference_filter(%(<a href="#{written_reference}">#{inner_html}</a>))

      expect(doc.children.first.children.first.attr('data-original')).to eq inner_html
    end

    it 'includes a data-reference-format attribute' do
      skip if written_reference.start_with?('<a')

      doc = reference_filter("Issue #{written_reference}+")
      link = doc.css('a').first

      expect(link).to have_attribute('data-reference-format')
      expect(link.attr('data-reference-format')).to eq('+')
      expect(link.attr('href')).to eq(work_item_url)
    end

    it 'includes a data-reference-format attribute for URL references' do
      doc = reference_filter("Issue #{work_item_url}+")
      link = doc.css('a').first

      expect(link).to have_attribute('data-reference-format')
      expect(link.attr('data-reference-format')).to eq('+')
      expect(link.attr('href')).to eq(work_item_url)
    end

    it 'includes a data-reference-format attribute for extended summary URL references' do
      doc = reference_filter("Issue #{work_item_url}+s")
      link = doc.css('a').first

      expect(link).to have_attribute('data-reference-format')
      expect(link.attr('data-reference-format')).to eq('+s')
      expect(link.attr('href')).to eq(work_item_url)
    end

    it 'does not process links containing issue numbers followed by text' do
      href = "#{written_reference}st"
      doc = reference_filter("<a href='#{href}'></a>")
      link = doc.css('a').first.attr('href')

      expect(link).to eq(href)
    end
  end

  context 'when group level work item URL reference' do
    let_it_be(:work_item, reload: true) { create(:work_item, :group_level, namespace: group) }
    let_it_be(:work_item_url)     { item_url(work_item) }
    let_it_be(:reference)         { work_item_url }
    let_it_be(:written_reference) { reference }
    let_it_be(:inner_text)        { written_reference }

    it_behaves_like 'a work item reference'
  end

  context 'when group level work item full reference' do
    let_it_be(:work_item, reload: true) { create(:work_item, :group_level, namespace: group) }
    let_it_be(:work_item_url)     { item_url(work_item) }
    let_it_be(:reference)         { work_item.to_reference(full: true) }
    let_it_be(:written_reference) { reference }
    let_it_be(:inner_text)        { written_reference }

    it_behaves_like 'a work item reference'
  end

  # Example:
  #   "See http://localhost/cross-namespace/cross-project/-/work_items/1"
  context 'when cross-project URL reference' do
    let_it_be(:work_item, reload: true) { create(:work_item, project: cross_project) }
    let_it_be(:work_item_url)     { item_url(work_item) }
    let_it_be(:reference)         { work_item_url }
    let_it_be(:written_reference) { reference }
    let_it_be(:inner_text)        { written_reference }

    it_behaves_like 'a work item reference'

    it 'includes a data-project attribute' do
      doc = reference_filter("Issue #{written_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq cross_project.id.to_s
    end

    it 'includes data attributes for issuable popover' do
      doc = reference_filter("See #{written_reference}")
      link = doc.css('a').first

      expect(link.attr('data-project-path')).to eq cross_project.full_path
      expect(link.attr('data-namespace-path')).to eq cross_project.full_path
      expect(link.attr('data-iid')).to eq work_item.iid.to_s
    end
  end

  # Example:
  #   "See http://localhost/cross-namespace/cross-project/-/work_items/1#note_123"
  context 'when cross-project URL reference with comment anchor' do
    let_it_be(:work_item)     { create(:work_item, project: cross_project) }
    let_it_be(:work_item_url) { item_url(work_item) }
    let_it_be(:reference)     { "#{work_item_url}#note_123" }

    it_behaves_like 'a reference containing an element node'

    it_behaves_like 'a reference with work item type information'

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq reference
    end

    it 'link with trailing slash' do
      doc = reference_filter("Fixed (#{work_item_url}/.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(work_item.to_reference(project))}</a>\.\)})
    end

    it 'links with adjacent text', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/478370' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(work_item.to_reference(project))} \(comment 123\)</a>\.\)})
    end
  end

  # Example:
  #   'See <a href=\"http://localhost/cross-namespace/cross-project/-/work_items/1\">Reference</a>''
  context 'when cross-project URL in link href' do
    let_it_be(:work_item, reload: true) { create(:work_item, project: cross_project) }
    let_it_be(:work_item_url)     { item_url(work_item) }
    let_it_be(:reference)         { work_item_url }
    let_it_be(:reference_link)    { %(<a href="#{reference}">Reference</a>) }
    let_it_be(:written_reference) { reference_link }
    let_it_be(:inner_text)        { 'Reference' }

    it_behaves_like 'a work item reference'

    it 'includes a data-project attribute' do
      doc = reference_filter("Issue #{written_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq cross_project.id.to_s
    end

    it 'includes data attributes for issuable popover' do
      doc = reference_filter("See #{written_reference}")
      link = doc.css('a').first

      expect(link.attr('data-project-path')).to eq cross_project.full_path
      expect(link.attr('data-namespace-path')).to eq cross_project.full_path
      expect(link.attr('data-iid')).to eq work_item.iid.to_s
    end
  end

  context 'for group context' do
    let_it_be(:context) { { project: nil, group: group } }
    let(:work_item_url) { item_url(work_item) }

    context 'when work item exists at the group level' do
      let_it_be(:work_item) { create(:work_item, :group_level, namespace: group) }

      it 'includes data attributes for issuable popover' do
        doc = reference_filter("See #{work_item_url}", context)
        link = doc.css('a').first

        expect(link.attr('data-namespace-path')).to eq(group.full_path)
        expect(link.attr('data-iid')).to eq(work_item.iid.to_s)
      end

      it 'links to a valid group level work item by URL' do
        doc = reference_filter("See #{work_item_url}", context)

        link = doc.css('a').first

        expect(link.attr('href')).to eq(work_item_url)
        expect(link.text).to eq("##{work_item.iid}")
      end

      it 'links to a valid group level work item with short reference' do
        doc = reference_filter("See #{work_item.to_reference}", context)

        link = doc.css('a').first

        expect(link.attr('href')).to eq(work_item_url)
        expect(link.text).to eq("##{work_item.iid}")
      end

      it 'links to a valid group level work item with long reference' do
        doc = reference_filter("See #{work_item.to_reference(full: true)}", context)

        link = doc.css('a').first

        expect(link.attr('href')).to eq(work_item_url)
        expect(link.text).to eq("##{work_item.iid}")
      end

      context 'when work item belongs to a different group than the one from the context' do
        it 'links to a valid group level work item with long reference' do
          doc = reference_filter("See #{work_item.to_reference(full: true)}", group: create(:group))

          link = doc.css('a').first

          expect(link.attr('href')).to eq(work_item_url)
          expect(link.text).to eq("#{group.full_path}##{work_item.iid}")
        end
      end
    end

    it 'links to a valid reference for url cross-namespace' do
      reference = "#{work_item_url}#note_123"

      doc = reference_filter("See #{reference}", context)

      link = doc.css('a').first
      expect(link.attr('href')).to eq("#{work_item_url}#note_123")
      expect(link.text).to include("#{project.full_path}##{work_item.iid}")
    end

    it 'links to a valid reference for cross-namespace in link href' do
      reference = "#{work_item_url}#note_123"
      reference_link = %(<a href="#{reference}">Reference</a>)

      doc = reference_filter("See #{reference_link}", context)

      link = doc.css('a').first
      expect(link.attr('href')).to eq("#{work_item_url}#note_123")
      expect(link.text).to include('Reference')
    end
  end

  describe 'performance' do
    let(:another_work_item) { create(:work_item, project: project) }

    it 'does not have a N+1 query problem' do
      single_reference = "Work item #{work_item.to_reference}"
      multiple_references = "Work items #{work_item.to_reference} and #{another_work_item.to_reference}"

      control = ActiveRecord::QueryRecorder.new { reference_filter(single_reference).to_html }

      expect { reference_filter(multiple_references).to_html }.not_to exceed_query_limit(control)
    end
  end
end
