# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::AlertReferenceFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:project)   { create(:project, :public) }
  let_it_be(:alert)     { create(:alert_management_alert, project: project) }
  let_it_be(:reference) { alert.to_reference }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w[pre code a style].each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      act = "<#{elem}>Alert #{reference}</#{elem}>"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'internal reference' do
    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq alert.details_url
    end

    it 'links with adjacent text' do
      doc = reference_filter("Alert (#{reference}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(reference)}</a>\.\)})
    end

    it 'ignores invalid alert IDs' do
      act = "Alert #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end

    it 'includes a title attribute' do
      doc = reference_filter("Alert #{reference}")

      expect(doc.css('a').first.attr('title')).to eq alert.title
    end

    it 'escapes the title attribute' do
      allow(alert).to receive(:title).and_return(%("></a>whatever<a title="))
      doc = reference_filter("Alert #{reference}")

      expect(doc.text).to eq "Alert #{reference}"
    end

    it 'includes default classes' do
      doc = reference_filter("Alert #{reference}")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-alert has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Alert #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-alert attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-alert')
      expect(link.attr('data-alert')).to eq alert.id.to_s
    end

    it 'supports an :only_path context' do
      doc = reference_filter("Alert #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r{https?://}
      expect(link).to eq urls.details_project_alert_management_url(project, alert.iid, only_path: true)
    end
  end

  context 'cross-project / cross-namespace complete reference' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project2)  { create(:project, :public, namespace: namespace) }
    let_it_be(:alert)     { create(:alert_management_alert, project: project2) }
    let_it_be(:reference) { "#{project2.full_path}^alert##{alert.iid}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq alert.details_url
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text).to eql(reference)
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text).to eql("See (#{reference}.)")
    end

    it 'ignores invalid alert IDs on the referenced project' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project / same-namespace complete reference' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project)   { create(:project, :public, namespace: namespace) }
    let_it_be(:project2)  { create(:project, :public, namespace: namespace) }
    let_it_be(:alert)     { create(:alert_management_alert, project: project2) }
    let_it_be(:reference) { "#{project2.full_path}^alert##{alert.iid}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq alert.details_url
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{project2.path}^alert##{alert.iid}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}^alert##{alert.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{project2.path}^alert##{alert.iid}.)")

      expect(doc.text).to eql("See (#{project2.path}^alert##{alert.iid}.)")
    end

    it 'ignores invalid alert IDs on the referenced project' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project shorthand reference' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project)   { create(:project, :public, namespace: namespace) }
    let_it_be(:project2)  { create(:project, :public, namespace: namespace) }
    let_it_be(:alert)     { create(:alert_management_alert, project: project2) }
    let_it_be(:reference) { "#{project2.path}^alert##{alert.iid}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq alert.details_url
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{project2.path}^alert##{alert.iid}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}^alert##{alert.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{project2.path}^alert##{alert.iid}.)")

      expect(doc.text).to eql("See (#{project2.path}^alert##{alert.iid}.)")
    end

    it 'ignores invalid alert IDs on the referenced project' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project URL reference' do
    let_it_be(:namespace) { create(:namespace, name: 'cross-reference') }
    let_it_be(:project2)  { create(:project, :public, namespace: namespace) }
    let_it_be(:alert)     { create(:alert_management_alert, project: project2) }
    let_it_be(:reference) { alert.details_url }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq alert.details_url
    end

    it 'links with adjacent text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(alert.to_reference(project))}</a>\.\)})
    end

    it 'ignores invalid alert IDs on the referenced project' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to match(%r{<a.+>#{Regexp.escape(invalidate_reference(reference))}</a>})
    end
  end

  context 'group context' do
    let_it_be(:group) { create(:group) }

    it 'links to a valid reference' do
      reference = "#{project.full_path}^alert##{alert.iid}"
      result = reference_filter("See #{reference}", { project: nil, group: group })

      expect(result.css('a').first.attr('href')).to eq(alert.details_url)
    end

    it 'ignores internal references' do
      act = "See ^alert##{alert.iid}"

      expect(reference_filter(act, project: nil, group: group).to_html).to include act
    end
  end

  context 'checking N+1' do
    let(:namespace)        { create(:namespace) }
    let(:project2)         { create(:project, :public, namespace: namespace) }
    let(:alert2)           { create(:alert_management_alert, project: project2) }
    let(:alert_reference)  { alert.to_reference }
    let(:alert2_reference) { alert2.to_reference(full: true) }

    it 'does not have N+1 per multiple references per project', :use_sql_query_cache do
      markdown = alert_reference.to_s
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        reference_filter(markdown)
      end

      expect(control.count).to eq 1

      markdown = "#{alert_reference} ^alert#2 ^alert#3 ^alert#4 #{alert2_reference}"

      # Since we're not batching alert queries across projects,
      # we have to account for that.
      # 1 for routes to find routes.source_id of projects matching paths
      # 1 for projects belonging to the above routes
      # 1 for preloading routes of the projects
      # 1 for loading the namespaces associated to the project
      # 1 for loading the routes associated with the namespace
      # 1x2 for alerts in each project
      # Total == 7
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/330359
      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control).with_threshold(6)
    end
  end
end
