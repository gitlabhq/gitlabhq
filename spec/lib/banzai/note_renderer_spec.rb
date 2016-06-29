require 'spec_helper'

describe Banzai::NoteRenderer do
  describe '.render' do
    it 'renders a Note' do
      note = double(:note)
      project = double(:project)
      wiki = double(:wiki)
      user = double(:user)

      expect(Banzai::ObjectRenderer).to receive(:new).
        with(project, user,
             requested_path: 'foo',
             project_wiki: wiki,
             ref: 'bar',
             pipeline: :note).
        and_call_original

      expect_any_instance_of(Banzai::ObjectRenderer).
        to receive(:render).with([note], :note)

      described_class.render([note], project, user, 'foo', wiki, 'bar')
    end
  end
end
