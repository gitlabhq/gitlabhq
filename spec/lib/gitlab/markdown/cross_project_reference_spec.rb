require 'spec_helper'

module Gitlab::Markdown
  describe CrossProjectReference do
    # context in the html-pipeline sense, not in the rspec sense
    let(:context) do
      {
        current_user: double('user'),
        project: double('project')
      }
    end

    include described_class

    describe '#project_from_ref' do
      context 'when no project was referenced' do
        it 'returns the project from context' do
          expect(project_from_ref(nil)).to eq context[:project]
        end
      end

      context 'when referenced project does not exist' do
        it 'returns nil' do
          expect(project_from_ref('invalid/reference')).to be_nil
        end
      end

      context 'when referenced project exists' do
        let(:project2) { double('referenced project') }

        before do
          expect(Project).to receive(:find_with_namespace).
            with('cross/reference').and_return(project2)
        end

        context 'and the user has permission to read it' do
          it 'returns the referenced project' do
            expect(self).to receive(:user_can_reference_project?).
              with(project2).and_return(true)

            expect(project_from_ref('cross/reference')).to eq project2
          end
        end

        context 'and the user does not have permission to read it' do
          it 'returns nil' do
            expect(self).to receive(:user_can_reference_project?).
              with(project2).and_return(false)

            expect(project_from_ref('cross/reference')).to be_nil
          end
        end
      end
    end
  end
end
