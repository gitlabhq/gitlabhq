# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::CommitDescriptionPipeline, feature_category: :source_code_management do
  describe 'formatting a cherry-picked commit description html' do
    let_it_be(:project) { create(:project, :repository, :public) }

    it 'formats correctly' do
      markdown = <<~MESSAGE
        (cherry-picked from commit #{project.repository.commit.id})

        Co-authored-by: example <example@example.com>
      MESSAGE

      result = described_class.call(markdown, project: project)

      expect(result[:output].to_html).to include("</a>)\n\nCo-authored-by")
    end
  end
end
