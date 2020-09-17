(function () {
  /**
   * Class responsible for filtering nodes from tree and options from legend
   * @param {MindMup} ysy
   * @constructor
   */
  function Filter(ysy) {
    this.ysy = ysy;
    this.allowedValues = [];
    this.init(ysy);
  }

  Filter.prototype.init = function (ysy) {
    var self = this;
    ysy.eventBus.register("nodeStyleChanged", function () {
      self.reset();
    });
  };

  Filter.prototype.className = "mindmup-node-filtered";
  Filter.prototype.pushAllowed = function (value) {
    this.allowedValues.push(value || 0);
    this.sweepNodes();
  };
  Filter.prototype.isOn = function(){
    return !!this.allowedValues.length;
  };
  Filter.prototype.removeAllowed = function (value) {
    this.allowedValues = _.without(this.allowedValues, value);
    this.sweepNodes();
  };
  Filter.prototype.toggleAllowed = function (value) {
    var store = this.ysy.styles.getCurrentStyle();
    if (store) this.store = store;
    if (_.contains(this.allowedValues, value)) {
      this.removeAllowed(value);
    } else {
      this.pushAllowed(value);
    }
  };
  Filter.prototype.cssByBannedValue = function (value) {
    if (!this.allowedValues.length) return "";
    return _.contains(this.allowedValues, value) ? "" : " " + this.className;
  };
  Filter.prototype.reset = function () {
    this.ysy.$container.find("." + this.className).removeClass(this.className);
    this.allowedValues = [];
  };
  /**
   *
   * @param {ModelEntity} idea
   * @return {boolean}
   */
  Filter.prototype.isBanned = function (idea) {
    if (!this.allowedValues.length) return false;
    if (idea.attr.isFresh) return false;
    var data = this.ysy.getData(idea);
    var value = this.store.value(data);
    return this.allowedValues.indexOf(value) === -1;
  };
  Filter.prototype.sweepNodes = function () {
    this.recursiveBanner(this.ysy.idea);
  };
  /**
   *
   * @param {ModelEntity} idea
   */
  Filter.prototype.recursiveBanner = function (idea) {
    var banned = this.isBanned(idea);
    var node = this.ysy.getNodeElement(idea);
    if (node.length) {
      node.toggleClass(this.className, banned);
    }
    if (idea.ideas) {
      _.each(idea.ideas, this.recursiveBanner, this)
    }
  };

  window.easyMindMupClasses.Filter = Filter;
})();
