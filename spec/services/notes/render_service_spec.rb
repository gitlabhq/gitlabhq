require 'spec_helper'

describe Notes::RenderService do
  describe '#execute' do
    it 'renders a Note' do
      note = double(:note)
      wiki = double(:wiki)
      user = double(:user)

      expect(Banzai::ObjectRenderer)
        .to receive(:new)
        .with(
          user: user,
          redaction_context: {
              requested_path: 'foo',
              project_wiki: wiki,
              ref: 'bar',
              only_path: nil,
              xhtml: false
          }
        )
        .and_call_original

      expect_any_instance_of(Banzai::ObjectRenderer)
        .to receive(:render)
        .with([note], :note)

      described_class.new(user).execute([note],
                                        requested_path: 'foo',
                                        project_wiki: wiki,
                                        ref: 'bar',
                                        only_path: nil,
                                        xhtml: false)
    end
  end
end
