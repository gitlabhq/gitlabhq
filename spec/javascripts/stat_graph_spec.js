describe("StatGraph", function () {

  describe("#get_log", function () {
    it("returns log", function () {
      StatGraph.log = "test";
      expect(StatGraph.get_log()).toBe("test");
    });
  });

  describe("#set_log", function () {
    it("sets the log", function () {
      StatGraph.set_log("test");
      expect(StatGraph.log).toBe("test");
    })
  })

});
