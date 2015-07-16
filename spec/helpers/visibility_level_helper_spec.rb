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

  describe "skip_level?" do
    describe "forks" do
      let(:project) { create(:project, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }
      let(:fork_project) { create(:forked_project_with_submodules) }

      before do
        fork_project.build_forked_project_link(forked_to_project_id: fork_project.id, forked_from_project_id: project.id)
        fork_project.save
      end

      it "skips levels" do
        expect(skip_level?(fork_project, Gitlab::VisibilityLevel::PUBLIC)).to be_truthy
        expect(skip_level?(fork_project, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(skip_level?(fork_project, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

    describe "non-forked project" do
      let(:project) { create(:project, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }

      it "skips levels" do
        expect(skip_level?(project, Gitlab::VisibilityLevel::PUBLIC)).to be_falsey
        expect(skip_level?(project, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(skip_level?(project, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

    describe "Snippet" do
      let(:snippet) { create(:snippet, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }

      it "skips levels" do
        expect(skip_level?(snippet, Gitlab::VisibilityLevel::PUBLIC)).to be_falsey
        expect(skip_level?(snippet, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(skip_level?(snippet, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

  end
end
