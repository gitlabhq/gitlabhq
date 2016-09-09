require 'spec_helper'

describe 'ci/lints/show' do
  let(:content) do
    { build_template: {
        script: './build.sh',
        tags: ['dotnet'],
        only: ['test@dude/repo'],
        except: ['deploy'],
        environment: 'testing'
      }
    }
  end
  let(:config_processor) { Ci::GitlabCiYamlProcessor.new(YAML.dump(content)) }

  context 'when content is valid' do
    before do
      assign(:status, true)
      assign(:builds, config_processor.builds)
      assign(:stages, config_processor.stages)
    end

    it 'shows correct values' do
      render

      expect(rendered).to have_content('Tag list: dotnet')
      expect(rendered).to have_content('Refs only: test@dude/repo')
      expect(rendered).to have_content('Refs except: deploy')
      expect(rendered).to have_content('Environment: testing')
      expect(rendered).to have_content('When: on_success')
    end
  end
end
