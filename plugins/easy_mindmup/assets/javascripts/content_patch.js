(function () {
  /**
   *
   * @param {MindMup} ysy
   * @property {MindMup} ysy
   * @constructor
   */
  function ContentPatch(ysy) {
    this.ysy = ysy;
    this.patch(ysy);
  }

  /**
   *
   * @param {MindMup} ysy
   */
  ContentPatch.prototype.patch = function (ysy) {
    var self = this;
    ysy.eventBus.register("TreeLoaded", /** @param {RootIdea} contentAggregate*/ function (contentAggregate) {
      var commandProcessors = contentAggregate.getCommandProcessors();
      contentAggregate.clone = function (subIdeaId) {
        var toClone = (subIdeaId && subIdeaId != contentAggregate.id && contentAggregate.findSubIdeaById(subIdeaId)) || contentAggregate;
        var cloned = JSON.parse(JSON.stringify(toClone));
        ysy.util.traverse(cloned, function (node) {
          ysy.getData(node).id = null;
        });
        return cloned;
      };
      commandProcessors.setData = function (originId, idea, obj) {
        ysy.setData(idea, obj);
      };
      commandProcessors.setCustomData = function (originId, idea, obj) {
        ysy.setCustomData(idea, obj);
      };
      contentAggregate.updateOneSide = $.proxy(self.updateOneSide, self);
    });
  };
  /**
   *
   * @param {RootIdea} idea
   */
  ContentPatch.prototype.updateOneSide = function (idea) {
    var i;
    var oneSideOn = this.ysy.settings.oneSideOn;
    if (oneSideOn === idea.oneSideOn) return;
    var ranks = Object.getOwnPropertyNames(idea.ideas).map(function (i) {
      return parseFloat(i);
    }).sort(function (a, b) {
      return a - b
    });
    if (ranks.length === 0) return;
    var constructed = {};
    if (oneSideOn) {
      var firstPositive = _.findIndex(ranks, function (rank) {
        return rank > 0;
      });
      var pointer = 1;
      for (i = firstPositive; i < ranks.length; i++) {
        constructed[pointer++] = idea.ideas[ranks[i]];
      }
      for (i = 0; i < firstPositive; i++) {
        constructed[pointer++] = idea.ideas[ranks[i]];
      }
    } else {
      if (ranks[0] < 0) {
        return;
      }
      var middlePoint = Math.ceil(ranks.length / 2);
      //index = i % 2 !== 0 ? -i / 2 - 0.5 : i / 2 + 1;
      for (i = 0; i < middlePoint; i++) {
        constructed[i + 1] = idea.ideas[ranks[i]];
      }
      for (i = middlePoint; i < ranks.length; i++) {
        constructed[i - ranks.length] = idea.ideas[ranks[i]];
      }
    }
    idea.oneSideOn = oneSideOn;
    idea.ideas = constructed;
    if (idea.dispatchEvent) {
      idea.dispatchEvent("changed");
    }
  };
  window.easyMindMupClasses.ContentPatch = ContentPatch;
})();