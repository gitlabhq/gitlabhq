# frozen_string_literal: true

require 'spec_helper'

describe NoteEntity do
  include Gitlab::Routing

  let(:request) { double('request', current_user: user, noteable: note.noteable) }

  let(:entity) { described_class.new(note, request: request) }
  let(:note) { create(:note) }
  let(:user) { create(:user) }

  subject { entity.as_json }

  it_behaves_like 'note entity'
end
