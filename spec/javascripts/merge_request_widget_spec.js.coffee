#= require merge_request_widget

describe 'MergeRequestWidget', ->

  beforeEach ->
    window.notifyPermissions = () ->
    window.notify = () ->
    @opts = {
      ci_status_url:"http://sampledomain.local/ci/getstatus",
      ci_status:"",
      ci_message: {
        normal: "Build {{status}} for \"{{title}}\"",
        preparing: "{{status}} build for \"{{title}}\""
      },
      ci_title: {
        preparing: "{{status}} build",
        normal: "Build {{status}}"
      },
      gitlab_icon:"gitlab_logo.png",
      builds_path:"http://sampledomain.local/sampleBuildsPath"
    }
    @class = new MergeRequestWidget(@opts)
    @ciStatusData = {"title":"Sample MR title","sha":"12a34bc5","status":"success","coverage":98}

  describe 'getCIStatus', ->
    beforeEach ->
      spyOn(jQuery, 'getJSON').and.callFake (req, cb) =>
        cb(@ciStatusData)

    it 'should call showCIStatus even if a notification should not be displayed', ->
      spy = spyOn(@class, 'showCIStatus').and.stub()
      @class.getCIStatus(false)
      expect(spy).toHaveBeenCalledWith(@ciStatusData.status)

    it 'should call showCIStatus when a notification should be displayed', ->
      spy = spyOn(@class, 'showCIStatus').and.stub()
      @class.getCIStatus(true)
      expect(spy).toHaveBeenCalledWith(@ciStatusData.status)

    it 'should call showCICoverage when the coverage rate is set', ->
      spy = spyOn(@class, 'showCICoverage').and.stub()
      @class.getCIStatus(false)
      expect(spy).toHaveBeenCalledWith(@ciStatusData.coverage)

    it 'should not call showCICoverage when the coverage rate is not set', ->
      @ciStatusData.coverage = null
      spy = spyOn(@class, 'showCICoverage').and.stub()
      @class.getCIStatus(false)
      expect(spy).not.toHaveBeenCalled()

    it 'should not display a notification on the first check after the widget has been created', ->
      spy = spyOn(window, 'notify')
      @class = new MergeRequestWidget(@opts)
      @class.getCIStatus(true)
      expect(spy).not.toHaveBeenCalled()
