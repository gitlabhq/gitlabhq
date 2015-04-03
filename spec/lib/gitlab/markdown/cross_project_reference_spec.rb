require 'spec_helper'

module Gitlab::Markdown
  describe CrossProjectReference do
    include CrossProjectReference

    describe '#project_from_ref' do
      let(:project) { double('project') }

      it 'returns a project from a valid reference' do
        expect(Project).to receive(:find_with_namespace).with('cross-reference/foo').and_return(project)

        expect(project_from_ref('cross-reference/foo')).to eq project
      end

      it 'returns the project from context when reference is invalid' do
        expect(self).to receive(:context).and_return({project: project})

        expect(project_from_ref('invalid/reference')).to eq project
      end
    end
  end
end
