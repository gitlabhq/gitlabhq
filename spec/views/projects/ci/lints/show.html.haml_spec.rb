# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/ci/lints/show' do
  include Devise::Test::ControllerHelpers
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let(:lint) { Gitlab::Ci::Lint.new(project: project, current_user: user) }
  let(:result) { lint.validate(YAML.dump(content)) }

  describe 'XSS protection' do
    before do
      assign(:project, project)
      assign(:result, result)
      stub_feature_flags(ci_lint_vue: false)
    end

    context 'when builds attrbiutes contain HTML nodes' do
      let(:content) do
        {
          rspec: {
            script: '<h1>rspec</h1>',
            stage: 'test'
          }
        }
      end

      it 'does not render HTML elements' do
        render

        expect(rendered).not_to have_css('h1', text: 'rspec')
      end
    end

    context 'when builds attributes do not contain HTML nodes' do
      let(:content) do
        {
          rspec: {
            script: 'rspec',
            stage: 'test'
          }
        }
      end

      it 'shows configuration in the table' do
        render

        expect(rendered).to have_css('td pre', text: 'rspec')
      end
    end
  end

  context 'when the content is valid' do
    let(:content) do
      {
        build_template: {
          script: './build.sh',
          tags: ['dotnet'],
          only: ['test@dude/repo'],
          except: ['deploy'],
          environment: 'testing'
        }
      }
    end

    before do
      assign(:project, project)
      assign(:result, result)
      stub_feature_flags(ci_lint_vue: false)
    end

    it 'shows the correct values' do
      render

      expect(rendered).to have_content('Status: syntax is correct')
      expect(rendered).to have_content('Tag list: dotnet')
      expect(rendered).to have_content('Only policy: refs, test@dude/repo')
      expect(rendered).to have_content('Except policy: refs, deploy')
      expect(rendered).to have_content('Environment: testing')
      expect(rendered).to have_content('When: on_success')
    end

    context 'when content has warnings' do
      before do
        allow(result).to receive(:warnings).and_return(['Warning 1', 'Warning 2'])
      end

      it 'shows warning messages' do
        render

        expect(rendered).to have_content('2 warning(s) found:')
        expect(rendered).to have_content('Warning 1')
        expect(rendered).to have_content('Warning 2')
      end
    end
  end

  context 'when the content is invalid' do
    let(:content) { double(:content) }

    before do
      allow(result).to receive(:warnings).and_return(['Warning 1', 'Warning 2'])
      allow(result).to receive(:errors).and_return(['Undefined error'])

      assign(:project, project)
      assign(:result, result)
      stub_feature_flags(ci_lint_vue: false)
    end

    it 'shows error message' do
      render

      expect(rendered).to have_content('Status: syntax is incorrect')
      expect(rendered).to have_content('Undefined error')
      expect(rendered).not_to have_content('Tag list:')
    end

    it 'shows warning messages' do
      render

      expect(rendered).to have_content('2 warning(s) found:')
      expect(rendered).to have_content('Warning 1')
      expect(rendered).to have_content('Warning 2')
    end
  end
end
