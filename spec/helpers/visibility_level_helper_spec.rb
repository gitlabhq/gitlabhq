require 'spec_helper'

describe VisibilityLevelHelper do
  include Haml::Helpers

  before :all do
    init_haml_helpers
  end

  let(:project) { create(:project) }

  describe 'visibility_level_description' do
    shared_examples 'a visibility level description' do
      let(:desc) do
        visibility_level_description(Gitlab::VisibilityLevel::PRIVATE,
                                     form_model)
      end

      let(:expected_class) do
        class_name = case form_model.class.name
                     when 'String'
                       form_model
                     else
                       form_model.class.name
                     end

        class_name.match(/(project|snippet)$/i)[0]
      end

      it 'should refer to the correct class' do
        expect(desc).to match(/#{expected_class}/i)
      end
    end

    context 'form_model argument is a String' do
      context 'model object is a personal snippet' do
        it_behaves_like 'a visibility level description' do
          let(:form_model) { 'PersonalSnippet' }
        end
      end

      context 'model object is a project snippet' do
        it_behaves_like 'a visibility level description' do
          let(:form_model) { 'ProjectSnippet' }
        end
      end

      context 'model object is a project' do
        it_behaves_like 'a visibility level description' do
          let(:form_model) { 'Project' }
        end
      end
    end

    context 'form_model argument is a model object' do
      context 'model object is a personal snippet' do
        it_behaves_like 'a visibility level description' do
          let(:form_model) { create(:personal_snippet) }
        end
      end

      context 'model object is a project snippet' do
        it_behaves_like 'a visibility level description' do
          let(:form_model) { create(:project_snippet, project: project) }
        end
      end

      context 'model object is a project' do
        it_behaves_like 'a visibility level description' do
          let(:form_model) { project }
        end
      end
    end
  end
end
