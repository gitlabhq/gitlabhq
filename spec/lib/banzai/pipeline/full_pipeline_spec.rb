require 'rails_helper'

describe Banzai::Pipeline::FullPipeline do
  describe 'References' do
    let(:project) { create(:project, :public) }
    let(:issue)   { create(:issue, project: project) }

    it 'handles markdown inside a reference' do
      markdown = "[some `code` inside](#{issue.to_reference})"
      result = described_class.call(markdown, project: project)
      link_content = result[:output].css('a').inner_html
      expect(link_content).to eq('some <code>code</code> inside')
    end

    it 'sanitizes reference HTML' do
      link_label = '<script>bad things</script>'
      markdown = "[#{link_label}](#{issue.to_reference})"
      result = described_class.to_html(markdown, project: project)
      expect(result).not_to include(link_label)
    end

    it 'escapes the data-original attribute on a reference' do
      markdown = %Q{[">bad things](#{issue.to_reference})}
      result = described_class.to_html(markdown, project: project)
      expect(result).to include(%{data-original='\"&gt;bad things'})
    end
  end
end
