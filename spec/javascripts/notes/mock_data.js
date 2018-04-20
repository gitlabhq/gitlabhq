export const notesDataMock = {
  discussionsPath: '/gitlab-org/gitlab-ce/issues/26/discussions.json',
  lastFetchedAt: 1501862675,
  markdownDocsPath: '/help/user/markdown',
  newSessionPath: '/users/sign_in?redirect_to_referer=yes',
  notesPath: '/gitlab-org/gitlab-ce/noteable/issue/98/notes',
  quickActionsDocsPath: '/help/user/project/quick_actions',
  registerPath: '/users/sign_in?redirect_to_referer=yes#register-pane',
  totalNotes: 1,
  closePath: '/twitter/flight/issues/9.json?issue%5Bstate_event%5D=close',
  reopenPath: '/twitter/flight/issues/9.json?issue%5Bstate_event%5D=reopen',
  canAwardEmoji: true,
};

export const userDataMock = {
  avatar_url: 'mock_path',
  id: 1,
  name: 'Root',
  path: '/root',
  state: 'active',
  username: 'root',
};

export const noteableDataMock = {
  assignees: [],
  author_id: 1,
  branch_name: null,
  confidential: false,
  create_note_path: '/gitlab-org/gitlab-ce/notes?target_id=98&target_type=issue',
  created_at: '2017-02-07T10:11:18.395Z',
  current_user: {
    can_create_note: true,
    can_update: true,
    can_award_emoji: true,
  },
  description: '',
  due_date: null,
  human_time_estimate: null,
  human_total_time_spent: null,
  id: 98,
  iid: 26,
  labels: [],
  lock_version: null,
  milestone: null,
  milestone_id: null,
  moved_to_id: null,
  preview_note_path:
    '/gitlab-org/gitlab-ce/preview_markdown?quick_actions_target_id=98&quick_actions_target_type=Issue',
  project_id: 2,
  state: 'opened',
  time_estimate: 0,
  title: '14',
  total_time_spent: 0,
  noteable_note_url: '/group/project/merge_requests/1#note_1',
  updated_at: '2017-08-04T09:53:01.226Z',
  updated_by_id: 1,
  web_url: '/gitlab-org/gitlab-ce/issues/26',
  noteableType: 'issue',
};

export const lastFetchedAt = '1501862675';

export const individualNote = {
  expanded: true,
  id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
  individual_note: true,
  notes: [
    {
      id: 1390,
      attachment: {
        url: null,
        filename: null,
        image: false,
      },
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: 'test',
        path: '/root',
      },
      created_at: '2017-08-01T17: 09: 33.762Z',
      updated_at: '2017-08-01T17: 09: 33.762Z',
      system: false,
      noteable_id: 98,
      noteable_type: 'Issue',
      type: null,
      human_access: 'Owner',
      note: 'sdfdsaf',
      note_html: "<p dir='auto'>sdfdsaf</p>",
      current_user: {
        can_edit: true,
        can_award_emoji: true,
      },
      discussion_id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
      emoji_awardable: true,
      award_emoji: [
        { name: 'baseball', user: { id: 1, name: 'Root', username: 'root' } },
        { name: 'art', user: { id: 1, name: 'Root', username: 'root' } },
      ],
      toggle_award_path: '/gitlab-org/gitlab-ce/notes/1390/toggle_award_emoji',
      noteable_note_url: '/group/project/merge_requests/1#note_1',
      note_url: '/group/project/merge_requests/1#note_1',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1390&user_id=1',
      path: '/gitlab-org/gitlab-ce/notes/1390',
    },
  ],
  reply_id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
};

export const note = {
  id: 546,
  attachment: {
    url: null,
    filename: null,
    image: false,
  },
  author: {
    id: 1,
    name: 'Administrator',
    username: 'root',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    path: '/root',
  },
  created_at: '2017-08-10T15:24:03.087Z',
  updated_at: '2017-08-10T15:24:03.087Z',
  system: false,
  noteable_id: 67,
  noteable_type: 'Issue',
  noteable_iid: 7,
  type: null,
  human_access: 'Owner',
  note: 'Vel id placeat reprehenderit sit numquam.',
  note_html: '<p dir="auto">Vel id placeat reprehenderit sit numquam.</p>',
  current_user: {
    can_edit: true,
    can_award_emoji: true,
  },
  discussion_id: 'd3842a451b7f3d9a5dfce329515127b2d29a4cd0',
  emoji_awardable: true,
  award_emoji: [
    {
      name: 'baseball',
      user: {
        id: 1,
        name: 'Administrator',
        username: 'root',
      },
    },
    {
      name: 'bath_tone3',
      user: {
        id: 1,
        name: 'Administrator',
        username: 'root',
      },
    },
  ],
  toggle_award_path: '/gitlab-org/gitlab-ce/notes/546/toggle_award_emoji',
  note_url: '/group/project/merge_requests/1#note_1',
  noteable_note_url: '/group/project/merge_requests/1#note_1',
  report_abuse_path:
    '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F7%23note_546&user_id=1',
  path: '/gitlab-org/gitlab-ce/notes/546',
};

export const discussionMock = {
  id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
  reply_id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
  expanded: true,
  notes: [
    {
      id: 1395,
      attachment: {
        url: null,
        filename: null,
        image: false,
      },
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      created_at: '2017-08-02T10:51:58.559Z',
      updated_at: '2017-08-02T10:51:58.559Z',
      system: false,
      noteable_id: 98,
      noteable_type: 'Issue',
      type: 'DiscussionNote',
      human_access: 'Owner',
      note: 'THIS IS A DICUSSSION!',
      note_html: "<p dir='auto'>THIS IS A DICUSSSION!</p>",
      current_user: {
        can_edit: true,
        can_award_emoji: true,
      },
      discussion_id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
      emoji_awardable: true,
      award_emoji: [],
      noteable_note_url: '/group/project/merge_requests/1#note_1',
      toggle_award_path: '/gitlab-org/gitlab-ce/notes/1395/toggle_award_emoji',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1395&user_id=1',
      path: '/gitlab-org/gitlab-ce/notes/1395',
    },
    {
      id: 1396,
      attachment: {
        url: null,
        filename: null,
        image: false,
      },
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      created_at: '2017-08-02T10:56:50.980Z',
      updated_at: '2017-08-03T14:19:35.691Z',
      system: false,
      noteable_id: 98,
      noteable_type: 'Issue',
      type: 'DiscussionNote',
      human_access: 'Owner',
      note: 'sadfasdsdgdsf',
      note_html: "<p dir='auto'>sadfasdsdgdsf</p>",
      last_edited_at: '2017-08-03T14:19:35.691Z',
      last_edited_by: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      current_user: {
        can_edit: true,
        can_award_emoji: true,
      },
      discussion_id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
      emoji_awardable: true,
      award_emoji: [],
      toggle_award_path: '/gitlab-org/gitlab-ce/notes/1396/toggle_award_emoji',
      noteable_note_url: '/group/project/merge_requests/1#note_1',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1396&user_id=1',
      path: '/gitlab-org/gitlab-ce/notes/1396',
    },
    {
      id: 1437,
      attachment: {
        url: null,
        filename: null,
        image: false,
      },
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      created_at: '2017-08-03T18:11:18.780Z',
      updated_at: '2017-08-04T09:52:31.062Z',
      system: false,
      noteable_id: 98,
      noteable_type: 'Issue',
      type: 'DiscussionNote',
      human_access: 'Owner',
      note: 'adsfasf Should disappear',
      note_html: "<p dir='auto'>adsfasf Should disappear</p>",
      last_edited_at: '2017-08-04T09:52:31.062Z',
      last_edited_by: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      current_user: {
        can_edit: true,
        can_award_emoji: true,
      },
      discussion_id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
      emoji_awardable: true,
      award_emoji: [],
      noteable_note_url: '/group/project/merge_requests/1#note_1',
      toggle_award_path: '/gitlab-org/gitlab-ce/notes/1437/toggle_award_emoji',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1437&user_id=1',
      path: '/gitlab-org/gitlab-ce/notes/1437',
    },
  ],
  individual_note: false,
};

export const loggedOutnoteableData = {
  id: 98,
  iid: 26,
  author_id: 1,
  description: '',
  lock_version: 1,
  milestone_id: null,
  state: 'opened',
  title: 'asdsa',
  updated_by_id: 1,
  created_at: '2017-02-07T10:11:18.395Z',
  updated_at: '2017-08-08T10:22:51.564Z',
  time_estimate: 0,
  total_time_spent: 0,
  human_time_estimate: null,
  human_total_time_spent: null,
  milestone: null,
  labels: [],
  branch_name: null,
  confidential: false,
  assignees: [
    {
      id: 1,
      name: 'Root',
      username: 'root',
      state: 'active',
      avatar_url: null,
      web_url: 'http://localhost:3000/root',
    },
  ],
  due_date: null,
  moved_to_id: null,
  project_id: 2,
  web_url: '/gitlab-org/gitlab-ce/issues/26',
  current_user: {
    can_create_note: false,
    can_update: false,
  },
  noteable_note_url: '/group/project/merge_requests/1#note_1',
  create_note_path: '/gitlab-org/gitlab-ce/notes?target_id=98&target_type=issue',
  preview_note_path:
    '/gitlab-org/gitlab-ce/preview_markdown?quick_actions_target_id=98&quick_actions_target_type=Issue',
};

export const INDIVIDUAL_NOTE_RESPONSE_MAP = {
  GET: {
    '/gitlab-org/gitlab-ce/issues/26/discussions.json': [
      {
        id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
        reply_id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
        expanded: true,
        notes: [
          {
            id: 1390,
            attachment: {
              url: null,
              filename: null,
              image: false,
            },
            author: {
              id: 1,
              name: 'Root',
              username: 'root',
              state: 'active',
              avatar_url: null,
              path: '/root',
            },
            created_at: '2017-08-01T17:09:33.762Z',
            updated_at: '2017-08-01T17:09:33.762Z',
            system: false,
            noteable_id: 98,
            noteable_type: 'Issue',
            type: null,
            human_access: 'Owner',
            note: 'sdfdsaf',
            note_html: '\u003cp dir="auto"\u003esdfdsaf\u003c/p\u003e',
            current_user: {
              can_edit: true,
              can_award_emoji: true,
            },
            discussion_id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
            emoji_awardable: true,
            award_emoji: [
              {
                name: 'baseball',
                user: {
                  id: 1,
                  name: 'Root',
                  username: 'root',
                },
              },
              {
                name: 'art',
                user: {
                  id: 1,
                  name: 'Root',
                  username: 'root',
                },
              },
            ],
            noteable_note_url: '/group/project/merge_requests/1#note_1',
            toggle_award_path: '/gitlab-org/gitlab-ce/notes/1390/toggle_award_emoji',
            report_abuse_path:
              '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1390\u0026user_id=1',
            path: '/gitlab-org/gitlab-ce/notes/1390',
          },
        ],
        individual_note: true,
      },
      {
        id: '70d5c92a4039a36c70100c6691c18c27e4b0a790',
        reply_id: '70d5c92a4039a36c70100c6691c18c27e4b0a790',
        expanded: true,
        notes: [
          {
            id: 1391,
            attachment: {
              url: null,
              filename: null,
              image: false,
            },
            author: {
              id: 1,
              name: 'Root',
              username: 'root',
              state: 'active',
              avatar_url: null,
              path: '/root',
            },
            created_at: '2017-08-02T10:51:38.685Z',
            updated_at: '2017-08-02T10:51:38.685Z',
            system: false,
            noteable_id: 98,
            noteable_type: 'Issue',
            type: null,
            human_access: 'Owner',
            note: 'New note!',
            note_html: '\u003cp dir="auto"\u003eNew note!\u003c/p\u003e',
            current_user: {
              can_edit: true,
              can_award_emoji: true,
            },
            discussion_id: '70d5c92a4039a36c70100c6691c18c27e4b0a790',
            emoji_awardable: true,
            award_emoji: [],
            noteable_note_url: '/group/project/merge_requests/1#note_1',
            toggle_award_path: '/gitlab-org/gitlab-ce/notes/1391/toggle_award_emoji',
            report_abuse_path:
              '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1391\u0026user_id=1',
            path: '/gitlab-org/gitlab-ce/notes/1391',
          },
        ],
        individual_note: true,
      },
    ],
    '/gitlab-org/gitlab-ce/noteable/issue/98/notes': {
      last_fetched_at: 1512900838,
      notes: [],
    },
  },
  PUT: {
    '/gitlab-org/gitlab-ce/notes/1471': {
      commands_changes: null,
      valid: true,
      id: 1471,
      attachment: null,
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      created_at: '2017-08-08T16:53:00.666Z',
      updated_at: '2017-12-10T11:03:21.876Z',
      system: false,
      noteable_id: 124,
      noteable_type: 'Issue',
      noteable_iid: 29,
      type: 'DiscussionNote',
      human_access: 'Owner',
      note: 'Adding a comment',
      note_html: '\u003cp dir="auto"\u003eAdding a comment\u003c/p\u003e',
      last_edited_at: '2017-12-10T11:03:21.876Z',
      last_edited_by: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      current_user: {
        can_edit: true,
        can_award_emoji: true,
      },
      discussion_id: 'a3ed36e29b1957efb3b68c53e2d7a2b24b1df052',
      emoji_awardable: true,
      award_emoji: [],
      noteable_note_url: '/group/project/merge_requests/1#note_1',
      toggle_award_path: '/gitlab-org/gitlab-ce/notes/1471/toggle_award_emoji',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F29%23note_1471\u0026user_id=1',
      path: '/gitlab-org/gitlab-ce/notes/1471',
    },
  },
};

export const DISCUSSION_NOTE_RESPONSE_MAP = {
  ...INDIVIDUAL_NOTE_RESPONSE_MAP,
  GET: {
    ...INDIVIDUAL_NOTE_RESPONSE_MAP.GET,
    '/gitlab-org/gitlab-ce/issues/26/discussions.json': [
      {
        id: 'a3ed36e29b1957efb3b68c53e2d7a2b24b1df052',
        reply_id: 'a3ed36e29b1957efb3b68c53e2d7a2b24b1df052',
        expanded: true,
        notes: [
          {
            id: 1471,
            attachment: {
              url: null,
              filename: null,
              image: false,
            },
            author: {
              id: 1,
              name: 'Root',
              username: 'root',
              state: 'active',
              avatar_url: null,
              path: '/root',
            },
            created_at: '2017-08-08T16:53:00.666Z',
            updated_at: '2017-08-08T16:53:00.666Z',
            system: false,
            noteable_id: 124,
            noteable_type: 'Issue',
            noteable_iid: 29,
            type: 'DiscussionNote',
            human_access: 'Owner',
            note: 'Adding a comment',
            note_html: '\u003cp dir="auto"\u003eAdding a comment\u003c/p\u003e',
            current_user: {
              can_edit: true,
              can_award_emoji: true,
            },
            discussion_id: 'a3ed36e29b1957efb3b68c53e2d7a2b24b1df052',
            emoji_awardable: true,
            award_emoji: [],
            toggle_award_path: '/gitlab-org/gitlab-ce/notes/1471/toggle_award_emoji',
            noteable_note_url: '/group/project/merge_requests/1#note_1',
            report_abuse_path:
              '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F29%23note_1471\u0026user_id=1',
            path: '/gitlab-org/gitlab-ce/notes/1471',
          },
        ],
        individual_note: false,
      },
    ],
  },
};

export function individualNoteInterceptor(request, next) {
  const body = INDIVIDUAL_NOTE_RESPONSE_MAP[request.method.toUpperCase()][request.url];

  next(
    request.respondWith(JSON.stringify(body), {
      status: 200,
    }),
  );
}

export function discussionNoteInterceptor(request, next) {
  const body = DISCUSSION_NOTE_RESPONSE_MAP[request.method.toUpperCase()][request.url];

  next(
    request.respondWith(JSON.stringify(body), {
      status: 200,
    }),
  );
}
