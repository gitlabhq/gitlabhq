describe("ContributorsStatGraphUtil", function () {

  describe("#parse_log", function () {
    it("returns a correctly parsed log", function () {
      var fake_log = [
            {author: "Karlo Soriano", date: "2013-05-09", additions: 471},
            {author: "Dmitriy Zaporozhets", date: "2013-05-08", additions: 6, deletions: 1},
            {author: "Dmitriy Zaporozhets", date: "2013-05-08", additions: 19, deletions: 3},
            {author: "Dmitriy Zaporozhets", date: "2013-05-08", additions: 29, deletions: 3}]
      
      var correct_parsed_log = {
        total: [
        {date: "2013-05-09", additions: 471, deletions: 0, commits: 1},
        {date: "2013-05-08", additions: 54, deletions: 7, commits: 3}],
        by_author:
        [
        { 
          author: "Karlo Soriano", 
          "2013-05-09": {date: "2013-05-09", additions: 471, deletions: 0, commits: 1}
        },
        {
          author: "Dmitriy Zaporozhets",
          "2013-05-08": {date: "2013-05-08", additions: 54, deletions: 7, commits: 3}
        }
        ]
      }
      expect(ContributorsStatGraphUtil.parse_log(fake_log)).toEqual(correct_parsed_log)
    })
  })

  describe("#store_data", function () {

    var fake_entry = {author: "Karlo Soriano", date: "2013-05-09", additions: 471}
    var fake_total = {}
    var fake_by_author = {}

    it("calls #store_commits", function () {
      spyOn(ContributorsStatGraphUtil, 'store_commits')
      ContributorsStatGraphUtil.store_data(fake_entry, fake_total, fake_by_author)
      expect(ContributorsStatGraphUtil.store_commits).toHaveBeenCalled()
    })

    it("calls #store_additions", function () {
      spyOn(ContributorsStatGraphUtil, 'store_additions')
      ContributorsStatGraphUtil.store_data(fake_entry, fake_total, fake_by_author)
      expect(ContributorsStatGraphUtil.store_additions).toHaveBeenCalled()
    })

    it("calls #store_deletions", function () {
      spyOn(ContributorsStatGraphUtil, 'store_deletions')
      ContributorsStatGraphUtil.store_data(fake_entry, fake_total, fake_by_author)
      expect(ContributorsStatGraphUtil.store_deletions).toHaveBeenCalled()
    })

  })

  describe("#store_commits", function () {
    var fake_total = "fake_total"
    var fake_by_author = "fake_by_author"

    it("calls #add twice with arguments fake_total and fake_by_author respectively", function () {
      spyOn(ContributorsStatGraphUtil, 'add')
      ContributorsStatGraphUtil.store_commits(fake_total, fake_by_author)
      expect(ContributorsStatGraphUtil.add.argsForCall).toEqual([["fake_total", "commits", 1], ["fake_by_author", "commits", 1]])
    })
  })

  describe("#add", function () {
    it("adds 1 to current test_field in collection", function () {
      var fake_collection = {test_field: 10}
      ContributorsStatGraphUtil.add(fake_collection, "test_field", 1)
      expect(fake_collection.test_field).toEqual(11)
    })

    it("inits and adds 1 if test_field in collection is not defined", function () {
      var fake_collection = {}
      ContributorsStatGraphUtil.add(fake_collection, "test_field", 1)
      expect(fake_collection.test_field).toEqual(1)
    })
  })

  describe("#store_additions", function () {
    var fake_entry = {additions: 10}
    var fake_total= "fake_total"
    var fake_by_author = "fake_by_author"
    it("calls #add twice with arguments fake_total and fake_by_author respectively", function () {
      spyOn(ContributorsStatGraphUtil, 'add')
      ContributorsStatGraphUtil.store_additions(fake_entry, fake_total, fake_by_author)
      expect(ContributorsStatGraphUtil.add.argsForCall).toEqual([["fake_total", "additions", 10], ["fake_by_author", "additions", 10]])
    })
  })

  describe("#store_deletions", function () {
    var fake_entry = {deletions: 10}
    var fake_total= "fake_total"
    var fake_by_author = "fake_by_author"
    it("calls #add twice with arguments fake_total and fake_by_author respectively", function () {
      spyOn(ContributorsStatGraphUtil, 'add')
      ContributorsStatGraphUtil.store_deletions(fake_entry, fake_total, fake_by_author)
      expect(ContributorsStatGraphUtil.add.argsForCall).toEqual([["fake_total", "deletions", 10], ["fake_by_author", "deletions", 10]])
    })
  })

  describe("#add_date", function () {
    it("adds a date field to the collection", function () {
      var fake_date = "2013-10-02"
      var fake_collection = {}
      ContributorsStatGraphUtil.add_date(fake_date, fake_collection)
      expect(fake_collection[fake_date].date).toEqual("2013-10-02")
    })
  })

  describe("#add_author", function () {
    it("adds an author field to the collection", function () {
      var fake_author = "Author"
      var fake_collection = {}
      ContributorsStatGraphUtil.add_author(fake_author, fake_collection)
      expect(fake_collection[fake_author].author).toEqual("Author")
    })
  })

  describe("#get_total_data", function () {
    it("returns the collection sorted via specified field", function () {
      var fake_parsed_log = {
      total: [{date: "2013-05-09", additions: 471, deletions: 0, commits: 1},
      {date: "2013-05-08", additions: 54, deletions: 7, commits: 3}],
      by_author:[
      { 
        author: "Karlo Soriano", 
        "2013-05-09": {date: "2013-05-09", additions: 471, deletions: 0, commits: 1}
      },
      {
        author: "Dmitriy Zaporozhets",
        "2013-05-08": {date: "2013-05-08", additions: 54, deletions: 7, commits: 3}
      }
      ]};
      var correct_total_data = [{date: "2013-05-08", commits: 3},
      {date: "2013-05-09", commits: 1}];
      expect(ContributorsStatGraphUtil.get_total_data(fake_parsed_log, "commits")).toEqual(correct_total_data)
    })
  })

  describe("#pick_field", function () {
    it("returns the collection with only the specified field and date", function () {
      var fake_parsed_log_total = [{date: "2013-05-09", additions: 471, deletions: 0, commits: 1},
      {date: "2013-05-08", additions: 54, deletions: 7, commits: 3}];
      ContributorsStatGraphUtil.pick_field(fake_parsed_log_total, "commits")
      var correct_pick_field_data = [{date: "2013-05-09", commits: 1},{date: "2013-05-08", commits: 3}];
      expect(ContributorsStatGraphUtil.pick_field(fake_parsed_log_total, "commits")).toEqual(correct_pick_field_data)
    })
  })

  describe("#get_author_data", function () {
    
  })


})