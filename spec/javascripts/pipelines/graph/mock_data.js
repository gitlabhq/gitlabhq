/* eslint-disable quote-props, quotes, comma-dangle */
export default {
  "id": 123,
  "user": {
    "name": "Root",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": null,
    "web_url": "http://localhost:3000/root"
  },
  "active": false,
  "coverage": null,
  "path": "/root/ci-mock/pipelines/123",
  "details": {
    "status": {
      "icon": "icon_status_success",
      "text": "passed",
      "label": "passed",
      "group": "success",
      "has_details": true,
      "details_path": "/root/ci-mock/pipelines/123",
      "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico"
    },
    "duration": 9,
    "finished_at": "2017-04-19T14:30:27.542Z",
    "stages": [{
      "name": "test",
      "title": "test: passed",
      "groups": [{
        "name": "test",
        "size": 1,
        "status": {
          "icon": "icon_status_success",
          "text": "passed",
          "label": "passed",
          "group": "success",
          "has_details": true,
          "details_path": "/root/ci-mock/builds/4153",
          "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
          "action": {
            "icon": "retry",
            "title": "Retry",
            "path": "/root/ci-mock/builds/4153/retry",
            "method": "post"
          }
        },
        "jobs": [{
          "id": 4153,
          "name": "test",
          "build_path": "/root/ci-mock/builds/4153",
          "retry_path": "/root/ci-mock/builds/4153/retry",
          "playable": false,
          "created_at": "2017-04-13T09:25:18.959Z",
          "updated_at": "2017-04-13T09:25:23.118Z",
          "status": {
            "icon": "icon_status_success",
            "text": "passed",
            "label": "passed",
            "group": "success",
            "has_details": true,
            "details_path": "/root/ci-mock/builds/4153",
            "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
            "action": {
              "icon": "retry",
              "title": "Retry",
              "path": "/root/ci-mock/builds/4153/retry",
              "method": "post"
            }
          }
        }]
      }],
      "status": {
        "icon": "icon_status_success",
        "text": "passed",
        "label": "passed",
        "group": "success",
        "has_details": true,
        "details_path": "/root/ci-mock/pipelines/123#test",
        "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico"
      },
      "path": "/root/ci-mock/pipelines/123#test",
      "dropdown_path": "/root/ci-mock/pipelines/123/stage.json?stage=test"
    }, {
      "name": "deploy",
      "title": "deploy: passed",
      "groups": [{
        "name": "deploy to production",
        "size": 1,
        "status": {
          "icon": "icon_status_success",
          "text": "passed",
          "label": "passed",
          "group": "success",
          "has_details": true,
          "details_path": "/root/ci-mock/builds/4166",
          "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
          "action": {
            "icon": "retry",
            "title": "Retry",
            "path": "/root/ci-mock/builds/4166/retry",
            "method": "post"
          }
        },
        "jobs": [{
          "id": 4166,
          "name": "deploy to production",
          "build_path": "/root/ci-mock/builds/4166",
          "retry_path": "/root/ci-mock/builds/4166/retry",
          "playable": false,
          "created_at": "2017-04-19T14:29:46.463Z",
          "updated_at": "2017-04-19T14:30:27.498Z",
          "status": {
            "icon": "icon_status_success",
            "text": "passed",
            "label": "passed",
            "group": "success",
            "has_details": true,
            "details_path": "/root/ci-mock/builds/4166",
            "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
            "action": {
              "icon": "retry",
              "title": "Retry",
              "path": "/root/ci-mock/builds/4166/retry",
              "method": "post"
            }
          }
        }]
      }, {
        "name": "deploy to staging",
        "size": 1,
        "status": {
          "icon": "icon_status_success",
          "text": "passed",
          "label": "passed",
          "group": "success",
          "has_details": true,
          "details_path": "/root/ci-mock/builds/4159",
          "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
          "action": {
            "icon": "retry",
            "title": "Retry",
            "path": "/root/ci-mock/builds/4159/retry",
            "method": "post"
          }
        },
        "jobs": [{
          "id": 4159,
          "name": "deploy to staging",
          "build_path": "/root/ci-mock/builds/4159",
          "retry_path": "/root/ci-mock/builds/4159/retry",
          "playable": false,
          "created_at": "2017-04-18T16:32:08.420Z",
          "updated_at": "2017-04-18T16:32:12.631Z",
          "status": {
            "icon": "icon_status_success",
            "text": "passed",
            "label": "passed",
            "group": "success",
            "has_details": true,
            "details_path": "/root/ci-mock/builds/4159",
            "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
            "action": {
              "icon": "retry",
              "title": "Retry",
              "path": "/root/ci-mock/builds/4159/retry",
              "method": "post"
            }
          }
        }]
      }],
      "status": {
        "icon": "icon_status_success",
        "text": "passed",
        "label": "passed",
        "group": "success",
        "has_details": true,
        "details_path": "/root/ci-mock/pipelines/123#deploy",
        "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico"
      },
      "path": "/root/ci-mock/pipelines/123#deploy",
      "dropdown_path": "/root/ci-mock/pipelines/123/stage.json?stage=deploy"
    }],
    "artifacts": [],
    "manual_actions": [{
      "name": "deploy to production",
      "path": "/root/ci-mock/builds/4166/play",
      "playable": false
    }]
  },
  "flags": {
    "latest": true,
    "triggered": false,
    "stuck": false,
    "yaml_errors": false,
    "retryable": false,
    "cancelable": false
  },
  "ref": {
    "name": "master",
    "path": "/root/ci-mock/tree/master",
    "tag": false,
    "branch": true
  },
  "commit": {
    "id": "798e5f902592192afaba73f4668ae30e56eae492",
    "short_id": "798e5f90",
    "title": "Merge branch 'new-branch' into 'master'\r",
    "created_at": "2017-04-13T10:25:17.000+01:00",
    "parent_ids": ["54d483b1ed156fbbf618886ddf7ab023e24f8738", "c8e2d38a6c538822e81c57022a6e3a0cfedebbcc"],
    "message": "Merge branch 'new-branch' into 'master'\r\n\r\nAdd new file\r\n\r\nSee merge request !1",
    "author_name": "Root",
    "author_email": "admin@example.com",
    "authored_date": "2017-04-13T10:25:17.000+01:00",
    "committer_name": "Root",
    "committer_email": "admin@example.com",
    "committed_date": "2017-04-13T10:25:17.000+01:00",
    "author": {
      "name": "Root",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": null,
      "web_url": "http://localhost:3000/root"
    },
    "author_gravatar_url": null,
    "commit_url": "http://localhost:3000/root/ci-mock/commit/798e5f902592192afaba73f4668ae30e56eae492",
    "commit_path": "/root/ci-mock/commit/798e5f902592192afaba73f4668ae30e56eae492"
  },
  "created_at": "2017-04-13T09:25:18.881Z",
  "updated_at": "2017-04-19T14:30:27.561Z"
};
