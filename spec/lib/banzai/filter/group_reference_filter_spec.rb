require 'spec_helper'

describe Banzai::Filter::GroupReferenceFilter, lib: true do
  include FilterSpecHelper

  let(:project) { create(:empty_project, :public) }
  let(:group) { create(:group) }
  let(:reference) { group.to_reference }

  context 'mentioning a group' do
    it_behaves_like 'a reference containing an element node'

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

  context 'mentioning a nested group' do
    it_behaves_like 'a reference containing an element node'

    let(:group)     { create(:group, :nested) }
    let(:reference) { group.to_reference }

    it 'links to the nested group' do
      doc = reference_filter("Hey #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.group_url(group)
    end
  end

  it 'supports an :only_path context' do
    doc = reference_filter("Hey #{reference}", only_path: true)
    link = doc.css('a').first.attr('href')

    expect(link).not_to match %r(https?://)
    expect(link).to eq urls.group_path(group)
  end

  describe '#groups' do
    it 'returns a Hash containing all groups' do
      document = Nokogiri::HTML.fragment("<p>#{group.to_reference}</p>")
      filter = described_class.new(document, project: project)

      expect(filter.groups).to eq({ group.path => group })
    end
  end
end
