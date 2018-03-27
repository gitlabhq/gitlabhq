require 'spec_helper'

describe 'ci/lints/show' do
  include Devise::Test::ControllerHelpers

  describe 'XSS protection' do
    let(:config_processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(content)) }

    before do
      assign(:status, true)
      assign(:builds, config_processor.builds)
      assign(:stages, config_processor.stages)
      assign(:jobs, config_processor.jobs)
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

  let(:config_processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(content)) }

  context 'when the content is valid' do
    before do
      assign(:status, true)
      assign(:builds, config_processor.builds)
      assign(:stages, config_processor.stages)
      assign(:jobs, config_processor.jobs)
    end

    it 'shows the correct values' do
      render

      expect(rendered).to have_content('Tag list: dotnet')
      expect(rendered).to have_content('Only policy: refs, test@dude/repo')
      expect(rendered).to have_content('Except policy: refs, deploy')
      expect(rendered).to have_content('Environment: testing')
      expect(rendered).to have_content('When: on_success')
    end
  end

  context 'when the content is invalid' do
    before do
      assign(:status, false)
      assign(:error, 'Undefined error')
    end

    it 'shows error message' do
      render

      expect(rendered).to have_content('Status: syntax is incorrect')
      expect(rendered).to have_content('Error: Undefined error')
      expect(rendered).not_to have_content('Tag list:')
    end
  end
end
