describe("ContributorsStatGraphUtil", function () {

  describe("#parse_log", function () {
    it("returns a correctly parsed log", function () {
      var fake_log = [
            {author_email: "karlo@email.com", author_name: "Karlo Soriano", date: "2013-05-09", additions: 471},
            {author_email: "dzaporozhets@email.com", author_name: "Dmitriy Zaporozhets", date: "2013-05-08", additions: 6, deletions: 1},
            {author_email: "dzaporozhets@email.com", author_name: "Dmitriy Zaporozhets", date: "2013-05-08", additions: 19, deletions: 3},
            {author_email: "dzaporozhets@email.com", author_name: "Dmitriy Zaporozhets", date: "2013-05-08", additions: 29, deletions: 3}]
      
      var correct_parsed_log = {
        total: [
        {date: "2013-05-09", additions: 471, deletions: 0, commits: 1},
        {date: "2013-05-08", additions: 54, deletions: 7, commits: 3}],
        by_author:
        [
        { 
          author_name: "Karlo Soriano", author_email: "karlo@email.com",
          "2013-05-09": {date: "2013-05-09", additions: 471, deletions: 0, commits: 1}
        },
        {
          author_name: "Dmitriy Zaporozhets",author_email: "dzaporozhets@email.com",
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

  // TODO: fix or remove
  //describe("#store_commits", function () {
    //var fake_total = "fake_total"
    //var fake_by_author = "fake_by_author"

    //it("calls #add twice with arguments fake_total and fake_by_author respectively", function () {
      //spyOn(ContributorsStatGraphUtil, 'add')
      //ContributorsStatGraphUtil.store_commits(fake_total, fake_by_author)
      //expect(ContributorsStatGraphUtil.add.argsForCall).toEqual([["fake_total", "commits", 1], ["fake_by_author", "commits", 1]])
    //})
  //})

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

  // TODO: fix or remove
  //describe("#store_additions", function () {
    //var fake_entry = {additions: 10}
    //var fake_total= "fake_total"
    //var fake_by_author = "fake_by_author"
    //it("calls #add twice with arguments fake_total and fake_by_author respectively", function () {
      //spyOn(ContributorsStatGraphUtil, 'add')
      //ContributorsStatGraphUtil.store_additions(fake_entry, fake_total, fake_by_author)
      //expect(ContributorsStatGraphUtil.add.argsForCall).toEqual([["fake_total", "additions", 10], ["fake_by_author", "additions", 10]])
    //})
  //})

  // TODO: fix or remove
  //describe("#store_deletions", function () {
    //var fake_entry = {deletions: 10}
    //var fake_total= "fake_total"
    //var fake_by_author = "fake_by_author"
    //it("calls #add twice with arguments fake_total and fake_by_author respectively", function () {
      //spyOn(ContributorsStatGraphUtil, 'add')
      //ContributorsStatGraphUtil.store_deletions(fake_entry, fake_total, fake_by_author)
      //expect(ContributorsStatGraphUtil.add.argsForCall).toEqual([["fake_total", "deletions", 10], ["fake_by_author", "deletions", 10]])
    //})
  //})

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
      var fake_author = { author_name: "Author", author_email: 'fake@email.com' }
      var fake_collection = {}
      ContributorsStatGraphUtil.add_author(fake_author, fake_collection)
      expect(fake_collection[fake_author.author_name].author_name).toEqual("Author")
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
    it("returns the log by author sorted by specified field", function () {
      var fake_parsed_log = {
        total: [
          {date: "2013-05-09", additions: 471, deletions: 0, commits: 1}, 
          {date: "2013-05-08", additions: 54, deletions: 7, commits: 3}
        ],
        by_author: [
          { 
            author_name: "Karlo Soriano", author_email: "karlo@email.com",
            "2013-05-09": {date: "2013-05-09", additions: 471, deletions: 0, commits: 1}
          },
          {
            author_name: "Dmitriy Zaporozhets", author_email: "dzaporozhets@email.com",
            "2013-05-08": {date: "2013-05-08", additions: 54, deletions: 7, commits: 3}
          }
        ]
      }
      var correct_author_data = [
        {author_name:"Dmitriy Zaporozhets",author_email:"dzaporozhets@email.com",dates:{"2013-05-08":3},deletions:7,additions:54,"commits":3},
        {author_name:"Karlo Soriano",author_email:"karlo@email.com",dates:{"2013-05-09":1},deletions:0,additions:471,commits:1}
      ]
      expect(ContributorsStatGraphUtil.get_author_data(fake_parsed_log, "commits")).toEqual(correct_author_data)
    })
  })

  describe("#parse_log_entry", function () {
    it("adds the corresponding info from the log entry to the author", function () {
      var fake_log_entry =    { author_name: "Karlo Soriano", author_email: "karlo@email.com",
        "2013-05-09": {date: "2013-05-09", additions: 471, deletions: 0, commits: 1}
      }
      var correct_parsed_log = {author_name:"Karlo Soriano",author_email:"karlo@email.com",dates:{"2013-05-09":1},deletions:0,additions:471,commits:1}
      expect(ContributorsStatGraphUtil.parse_log_entry(fake_log_entry, 'commits', null)).toEqual(correct_parsed_log)
    })
  })

  describe("#in_range", function () {
    var date = "2013-05-09"
    it("returns true if date_range is null", function () {
      expect(ContributorsStatGraphUtil.in_range(date, null)).toEqual(true)
    })
    it("returns true if date is in range", function () {
      var date_range = [new Date("2013-01-01"), new Date("2013-12-12")]
      expect(ContributorsStatGraphUtil.in_range(date, date_range)).toEqual(true)
    })
    it("returns false if date is not in range", function () {
      var date_range = [new Date("1999-12-01"), new Date("2000-12-01")]
      expect(ContributorsStatGraphUtil.in_range(date, date_range)).toEqual(false)
    })
  })


})
