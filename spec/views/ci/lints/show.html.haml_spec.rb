require 'spec_helper'

describe 'ci/lints/show' do
<<<<<<< HEAD
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
=======
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

  let(:config_processor) { Ci::GitlabCiYamlProcessor.new(YAML.dump(content)) }

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
      expect(rendered).to have_content('Refs only: test@dude/repo')
      expect(rendered).to have_content('Refs except: deploy')
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
>>>>>>> ce/master
    end
  end
end
