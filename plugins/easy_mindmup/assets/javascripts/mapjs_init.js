(function () {
  /**
   * Class responsible for initiation of MindMup mind map component
   * @param {MindMup} ysy
   * @constructor
   */
  function MMInitiator(ysy) {
    this.ysy = ysy;
  }

  /**
   *
   * @param {MindMup} ysy
   */
  MMInitiator.prototype.init = function (ysy) {
    // var imageInsertController = new MAPJS.ImageInsertController("http://localhost:4999?u=");
    var mapModel = new MAPJS.MapModel(ysy.layoutPatch.layoutCalculator, []);
    jQuery(ysy.$container).domMapWidget(console, mapModel, false, null, undefined, ysy);
    jQuery(ysy.$menu).mapToolbarWidget(mapModel, ysy);
    MAPJS.DOMRender.stageMargin = {top: 300, left: 300, bottom: 300, right: 300};
    MAPJS.DOMRender.linkConnectorPath = ysy.links.outerPath;
    MAPJS.DOMRender.nodeConnectorPath = ysy.domPatch.curvedPath;
    ysy.mapModel = mapModel;
    $(window).resize(function (event) {
      ysy.eventBus.fireEvent("resize", event)
    });
    // imageInsertController.addEventListener('imageInsertError', function (reason) {
    //   ysy.log.error('image insert error', reason);
    // });
  };

  window.easyMindMupClasses.MMInitiator = MMInitiator;
})();
