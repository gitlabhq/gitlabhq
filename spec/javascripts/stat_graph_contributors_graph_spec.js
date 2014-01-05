describe("ContributorsGraph", function () {
  describe("#set_x_domain", function () {
    it("set the x_domain", function () {
     ContributorsGraph.set_x_domain(20)
     expect(ContributorsGraph.prototype.x_domain).toEqual(20)
    })
  })
  
  describe("#set_y_domain", function () {
    it("sets the y_domain", function () {
      ContributorsGraph.set_y_domain([{commits: 30}])
      expect(ContributorsGraph.prototype.y_domain).toEqual([0, 30])
    })
  })

  describe("#init_x_domain", function () {
    it("sets the initial x_domain", function () {
      ContributorsGraph.init_x_domain([{date: "2013-01-31"}, {date: "2012-01-31"}])
      expect(ContributorsGraph.prototype.x_domain).toEqual(["2012-01-31", "2013-01-31"])
    })
  })

  describe("#init_y_domain", function () {
    it("sets the initial y_domain", function () {
      ContributorsGraph.init_y_domain([{commits: 30}])
      expect(ContributorsGraph.prototype.y_domain).toEqual([0, 30])
    })
  })

  describe("#init_domain", function () {
    it("calls init_x_domain and init_y_domain", function () {
      spyOn(ContributorsGraph, "init_x_domain")
      spyOn(ContributorsGraph, "init_y_domain")
      ContributorsGraph.init_domain()
      expect(ContributorsGraph.init_x_domain).toHaveBeenCalled()
      expect(ContributorsGraph.init_y_domain).toHaveBeenCalled()
    })
  })

  describe("#set_dates", function () {
    it("sets the dates", function () {
      ContributorsGraph.set_dates("2013-12-01")
      expect(ContributorsGraph.prototype.dates).toEqual("2013-12-01")
    })
  })

  describe("#set_x_domain", function () {
    it("sets the instance's x domain using the prototype's x_domain", function () {
      ContributorsGraph.prototype.x_domain = 20
      var instance = new ContributorsGraph()
      instance.x = d3.time.scale().range([0, 100]).clamp(true)
      spyOn(instance.x, 'domain')
      instance.set_x_domain()
      expect(instance.x.domain).toHaveBeenCalledWith(20)
    })
  })

  describe("#set_y_domain", function () {
    it("sets the instance's y domain using the prototype's y_domain", function () {
      ContributorsGraph.prototype.y_domain = 30
      var instance = new ContributorsGraph()
      instance.y = d3.scale.linear().range([100, 0]).nice()
      spyOn(instance.y, 'domain')
      instance.set_y_domain()
      expect(instance.y.domain).toHaveBeenCalledWith(30)
    })
  })

  describe("#set_domain", function () {
    it("calls set_x_domain and set_y_domain", function () {
      var instance = new ContributorsGraph()
      spyOn(instance, 'set_x_domain')
      spyOn(instance, 'set_y_domain')
      instance.set_domain()
      expect(instance.set_x_domain).toHaveBeenCalled()
      expect(instance.set_y_domain).toHaveBeenCalled()
    })
  })

  describe("#set_data", function () {
    it("sets the data", function () {
      var instance = new ContributorsGraph()
      instance.set_data("20")
      expect(instance.data).toEqual("20")
    })
  })
})

describe("ContributorsMasterGraph", function () {
  
  // TODO: fix or remove
  //describe("#process_dates", function () {
    //it("gets and parses dates", function () {
      //var graph = new ContributorsMasterGraph()
      //var data = 'random data here'
      //spyOn(graph, 'parse_dates')
      //spyOn(graph, 'get_dates').andReturn("get")
      //spyOn(ContributorsGraph,'set_dates').andCallThrough()
      //graph.process_dates(data)
      //expect(graph.parse_dates).toHaveBeenCalledWith(data)
      //expect(graph.get_dates).toHaveBeenCalledWith(data)
      //expect(ContributorsGraph.set_dates).toHaveBeenCalledWith("get")
    //})
  //}) 

  describe("#get_dates", function () {
    it("plucks the date field from data collection", function () {
      var graph = new ContributorsMasterGraph()
      var data = [{date: "2013-01-01"}, {date: "2012-12-15"}]
      expect(graph.get_dates(data)).toEqual(["2013-01-01", "2012-12-15"])
    })
  })

  describe("#parse_dates", function () {
    it("parses the dates", function () {
      var graph = new ContributorsMasterGraph()
      var parseDate = d3.time.format("%Y-%m-%d").parse
      var data = [{date: "2013-01-01"}, {date: "2012-12-15"}]
      var correct = [{date: parseDate(data[0].date)}, {date: parseDate(data[1].date)}]
      graph.parse_dates(data)
      expect(data).toEqual(correct)
    })
  })

  
})
