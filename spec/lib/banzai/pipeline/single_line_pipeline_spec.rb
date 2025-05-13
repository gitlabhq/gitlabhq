# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::SingleLinePipeline, feature_category: :markdown do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  it_behaves_like 'sanitize pipeline'

  it 'does not process markdown' do
    text = '_italic_'

    expect(to_html(text)).to eq(text)
  end

  it 'escapes HTML' do
    text = '<p>Hello<br>World</p>'

    expect(to_html(text)).to eq('&lt;p&gt;Hello&lt;br&gt;World&lt;/p&gt;')
  end

  it 'handles emojis and autolinking' do
    text = ':smile: using http://example.com'
    result = to_html(text)

    expect(result).to include('gl-emoji')
    expect(result).to include('<a href="http://example.com"')
  end

  it 'recognizes references' do
    text = "Issue #{issue.to_reference}, User #{user.to_reference}"
    result = to_html(text)

    expect(result).to include('data-reference-type="issue"')
    expect(result).to include('data-reference-type="user"')
  end

  def to_html(text)
    described_class.to_html(text, project: project, pipeline: :single_line)
  end
end
