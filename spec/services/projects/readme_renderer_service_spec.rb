# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ReadmeRendererService, '#execute', feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  subject(:service) { described_class.new(project, nil, opts) }

  let_it_be(:project) { create(:project, title: 'My Project', description: '_custom_description_') }

  let(:opts) { { default_branch: 'master' } }

  it 'renders the an ERB readme template' do
    expect(service.execute).to start_with(<<~MARKDOWN)
      # My Project

      _custom_description_

      ## Getting started

      To make it easy for you to get started with GitLab, here's a list of recommended next steps.

      Already a pro? Just edit this README.md and make it your own. Want to make it easy? [Use the template at the bottom](#editing-this-readme)!

      ## Add your files

      - [ ] [Create](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#create-a-file) or [upload](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#upload-a-file) files
      - [ ] [Add files using the command line](https://docs.gitlab.com/ee/gitlab-basics/add-file.html#add-a-file-using-the-command-line) or push an existing Git repository with the following command:

      ```
      cd existing_repo
      git remote add origin #{project.http_url_to_repo}
      git branch -M master
      git push -uf origin master
      ```
    MARKDOWN
  end

  context 'with a custom template' do
    before do
      allow(File).to receive(:read).and_call_original
    end

    it 'renders that template file' do
      opts[:template_name] = :custom_readme

      expect(service).to receive(:sanitized_filename).with(:custom_readme).and_return('custom_readme.md.tt')
      expect(File).to receive(:read).with('custom_readme.md.tt').and_return('_custom_readme_file_content_')
      expect(service.execute).to eq('_custom_readme_file_content_')
    end

    context 'with path traversal in mind' do
      where(:template_name, :exception, :expected_path) do
        '../path/traversal/bad' | [Gitlab::PathTraversal::PathTraversalAttackError, 'Invalid path'] | nil
        '/bad/template' | [StandardError, 'path /bad/template.md.tt is not allowed'] | nil
        'good/template' | nil | 'good/template.md.tt'
      end

      with_them do
        it 'raises the expected exception on bad paths' do
          opts[:template_name] = template_name

          if exception
            expect { subject.execute }.to raise_error(*exception)
          else
            expect(File).to receive(:read).with(described_class::TEMPLATE_PATH.join(expected_path).to_s).and_return('')

            expect { subject.execute }.not_to raise_error
          end
        end
      end
    end
  end
end
