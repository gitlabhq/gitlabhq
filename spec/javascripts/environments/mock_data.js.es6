const environmentsList = [
  {
    "id": 15,
    "project_id": 11,
    "name": "production",
    "created_at": "2016-10-18T10:47:46.840Z",
    "updated_at": "2016-10-19T15:49:24.378Z",
    "external_url": "https://test.com",
    "environment_type": null,
    "state": "available",
    "last_deployment": {
      "id": 57,
      "iid": 5,
      "project_id": 11,
      "environment_id": 15,
      "ref": "master",
      "tag": false,
      "sha": "edf8704ba6cea79be4634b82927e9ff534068428",
      "user_id": 1,
      "deployable_id": 1170,
      "deployable_type": "CommitStatus",
      "on_stop": null,
      "short_sha": "edf8704b",
      "commit_title": "Update .gitlab-ci.yml",
      "commit": {
        "id": "edf8704ba6cea79be4634b82927e9ff534068428",
        "message": "Update .gitlab-ci.yml",
        "parent_ids": ["f215999006bd3d5c89b9b1e8c0873c9aca0f913a"],
        "authored_date": "2016-10-19T16:49:09.000+01:00",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
        "committed_date": "2016-10-19T16:49:09.000+01:00",
        "committer_name": "Administrator",
        "committer_email": "admin@example.com"
      },
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon"
      },
      "deployable": {
        "id": 1170,
        "name": "deploy",
        "tag": false,
        "ref": "master"
      }
    },
    "project": {
      "id": 11,
      "name": "review-apps",
      "path": "review-apps",
      "namespace_id": 1,
      "namespace": {
        "id": 1,
        "name": "root"
      }
    }
  },{
    "id": 18,
    "project_id": 11,
    "name": "review/test-environment",
    "created_at": "2016-10-19T14:59:59.303Z",
    "updated_at": "2016-10-19T14:59:59.303Z",
    "external_url": "http://test1.com",
    "environment_type": "review",
    "state": "available",
    "project": {
      "id": 11,
      "name": "review-apps",
      "namespace": {
        "id": 1,
        "name": "root"
      }
    }
  },
  {
    "id": 18,
    "project_id": 11,
    "name": "review/test-environment-1",
    "created_at": "2016-10-19T14:59:59.303Z",
    "updated_at": "2016-10-19T14:59:59.303Z",
    "external_url": "http://test-1.com",
    "environment_type": "review",
    "state": "stopped",
    "project": {
      "id": 11,
      "name": "review-apps",
      "namespace": {
        "id": 1,
        "name": "root"
      }
    }
  }
];
