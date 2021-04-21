# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ci/syntax_templates' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:lint) { Gitlab::Ci::Lint.new(project: project, current_user: user) }

  before do
    project.add_developer(user)
  end

  subject(:lint_result) { lint.validate(content) }

  Dir.glob('lib/gitlab/ci/syntax_templates/**/*.yml').each do |template|
    describe template do
      let(:content) { File.read(template) }

      it 'validates the template' do
        expect(lint_result).to be_valid, "got errors: #{lint_result.errors.join(', ')}"
      end
    end
  end
end
