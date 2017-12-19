import { storiesOf } from '@storybook/vue';
import { withKnobs, boolean, select, number, text } from '@storybook/addon-knobs';
import {
  noteableDataMock,
  discussionMock,
  diffDiscussionMock,
  imageDiffDiscussionMock,
  notesDataMock,
  systemNoteMock,
} from '../../spec/javascripts/notes/mock_data';
import store from '~/notes/stores';
import NoteableDiscussion from '~/notes/components/noteable_discussion.vue';

import '~/commons/';
import '~/behaviors';
import '~/render_gfm';

(function syntaxHighlightHack() {
  window.gon = window.gon || {};
  window.gon.user_color_scheme = 'white';
}());

const stories = storiesOf('Notes', module);

store.dispatch('setNoteableData', noteableDataMock);
store.dispatch('setNotesData', notesDataMock);

function makeStory(note = {}) {
  console.log(note);
  return {
    store,
    components: {
      NoteableDiscussion,
    },
    data() {
      return {
        note,
      };
    },
    template: `
      <div class="c  ontainer-fluid container-limited limit-container-width">
        <ul class="notes">
          <noteable-discussion :note="note" />
        </ul>
      </div>
    `,
  };
}

stories.addDecorator(withKnobs);

const diff_file = { ...discussionMock.notes[0].diff_file };
const notes = [...discussionMock.notes];

stories.add('placeholder comment', () => makeStory({
  is_placeholder_note: true,
}));

stories.add('single comment', () => makeStory({
  individual_note: true,
  notes: [
    notes[0],
  ],
}));

stories.add('with replies', () => makeStory(discussionMock));

stories.add('text diff', () => makeStory({
  ...discussionMock,
  notes: [
    diffDiscussionMock,
  ],
}));

stories.add('image diff', () => makeStory({
  ...imageDiffDiscussionMock,
}));

stories.add('system notes.default system', () => makeStory({
  systemNoteMock,
}));
