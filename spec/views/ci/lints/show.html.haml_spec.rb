require 'spec_helper'

describe 'ci/lints/show' do
  include Devise::TestHelpers

  before do
    assign(:status, true)
    assign(:stages, %w[test])
    assign(:builds, builds)
  end

  context 'when builds attrbiutes contain HTML nodes' do
    let(:builds) do
      [ { name: 'rspec', stage: 'test', commands: '<h1>rspec</h1>' } ]
    end

    it 'does not render HTML elements' do
      render

      expect(rendered).not_to have_css('h1', text: 'rspec')
    end
  end

  context 'when builds attributes do not contain HTML nodes' do
    let(:builds) do
      [ { name: 'rspec', stage: 'test', commands: 'rspec' } ]
    end

    it 'shows configuration in the table' do
      render

      expect(rendered).to have_css('td pre', text: 'rspec')
    end
  end
end
