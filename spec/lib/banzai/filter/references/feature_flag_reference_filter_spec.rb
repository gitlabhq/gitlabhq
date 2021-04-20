# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::FeatureFlagReferenceFilter do
  include FilterSpecHelper

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:feature_flag) { create(:operations_feature_flag, project: project) }
  let_it_be(:reference) { feature_flag.to_reference }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Feature Flag #{reference}</#{elem}>"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'with internal reference' do
    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.edit_project_feature_flag_url(project, feature_flag)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Feature Flag (#{reference}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(reference)}</a>\.\)})
    end

    it 'ignores invalid feature flag IIDs' do
      exp = act = "Check [feature_flag:#{non_existing_record_id}]"

      expect(reference_filter(act).to_html).to eq exp
    end

    it 'includes a title attribute' do
      doc = reference_filter("Feature Flag #{reference}")

      expect(doc.css('a').first.attr('title')).to eq feature_flag.name
    end

    it 'escapes the title attribute' do
      allow(feature_flag).to receive(:name).and_return(%{"></a>whatever<a title="})
      doc = reference_filter("Feature Flag #{reference}")

      expect(doc.text).to eq "Feature Flag #{reference}"
    end

    it 'includes default classes' do
      doc = reference_filter("Feature Flag #{reference}")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-feature_flag has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Feature Flag #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-feature-flag attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-feature-flag')
      expect(link.attr('data-feature-flag')).to eq feature_flag.id.to_s
    end

    it 'supports an :only_path context' do
      doc = reference_filter("Feature Flag #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq urls.edit_project_feature_flag_url(project, feature_flag.iid, only_path: true)
    end
  end

  context 'with cross-project / cross-namespace complete reference' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project2)  { create(:project, :public, namespace: namespace) }
    let_it_be(:feature_flag) { create(:operations_feature_flag, project: project2) }
    let_it_be(:reference) { "[feature_flag:#{project2.full_path}/#{feature_flag.iid}]" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.edit_project_feature_flag_url(project2, feature_flag)
    end

    it 'produces a valid text in a link' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text).to eql(reference)
    end

    it 'produces a valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text).to eql("See (#{reference}.)")
    end

    it 'ignores invalid feature flag IIDs on the referenced project' do
      exp = act = "Check [feature_flag:#{non_existing_record_id}]"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'with cross-project / same-namespace complete reference' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project)   { create(:project, :public, namespace: namespace) }
    let_it_be(:project2)  { create(:project, :public, namespace: namespace) }
    let_it_be(:feature_flag) { create(:operations_feature_flag, project: project2) }
    let_it_be(:reference) { "[feature_flag:#{project2.full_path}/#{feature_flag.iid}]" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.edit_project_feature_flag_url(project2, feature_flag)
    end

    it 'produces a valid text in a link' do
      doc = reference_filter("See ([feature_flag:#{project2.path}/#{feature_flag.iid}].)")

      expect(doc.css('a').first.text).to eql("[feature_flag:#{project2.path}/#{feature_flag.iid}]")
    end

    it 'produces a valid text' do
      doc = reference_filter("See ([feature_flag:#{project2.path}/#{feature_flag.iid}].)")

      expect(doc.text).to eql("See ([feature_flag:#{project2.path}/#{feature_flag.iid}].)")
    end

    it 'ignores invalid feature flag IIDs on the referenced project' do
      exp = act = "Check [feature_flag:#{non_existing_record_id}]"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'with cross-project shorthand reference' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project)   { create(:project, :public, namespace: namespace) }
    let_it_be(:project2)  { create(:project, :public, namespace: namespace) }
    let_it_be(:feature_flag) { create(:operations_feature_flag, project: project2) }
    let_it_be(:reference) { "[feature_flag:#{project2.path}/#{feature_flag.iid}]" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.edit_project_feature_flag_url(project2, feature_flag)
    end

    it 'produces a valid text in a link' do
      doc = reference_filter("See ([feature_flag:#{project2.path}/#{feature_flag.iid}].)")

      expect(doc.css('a').first.text).to eql("[feature_flag:#{project2.path}/#{feature_flag.iid}]")
    end

    it 'produces a valid text' do
      doc = reference_filter("See ([feature_flag:#{project2.path}/#{feature_flag.iid}].)")

      expect(doc.text).to eql("See ([feature_flag:#{project2.path}/#{feature_flag.iid}].)")
    end

    it 'ignores invalid feature flag IDs on the referenced project' do
      exp = act = "Check [feature_flag:#{non_existing_record_id}]"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'with cross-project URL reference' do
    let_it_be(:namespace) { create(:namespace, name: 'cross-reference') }
    let_it_be(:project2)  { create(:project, :public, namespace: namespace) }
    let_it_be(:feature_flag) { create(:operations_feature_flag, project: project2) }
    let_it_be(:reference) { urls.edit_project_feature_flag_url(project2, feature_flag) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.edit_project_feature_flag_url(project2, feature_flag)
    end

    it 'links with adjacent text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(feature_flag.to_reference(project))}</a>\.\)})
    end

    it 'ignores invalid feature flag IIDs on the referenced project' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to match(%r{<a.+>#{Regexp.escape(invalidate_reference(reference))}</a>})
    end
  end

  context 'with group context' do
    let_it_be(:group) { create(:group) }

    it 'links to a valid reference' do
      reference = "[feature_flag:#{project.full_path}/#{feature_flag.iid}]"
      result = reference_filter("See #{reference}", { project: nil, group: group } )

      expect(result.css('a').first.attr('href')).to eq(urls.edit_project_feature_flag_url(project, feature_flag))
    end

    it 'ignores internal references' do
      exp = act = "See [feature_flag:#{feature_flag.iid}]"

      expect(reference_filter(act, project: nil, group: group).to_html).to eq exp
    end
  end
end
