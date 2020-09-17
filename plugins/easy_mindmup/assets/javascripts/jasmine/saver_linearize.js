describe("Saver linearize", function () {
  it("should return [] for only project", function () {
    var ysy = jasmine.ysyInstance;
    var project = new window.easyMindMupClasses.RootIdea(ysy);
    project.fromServer(5, "Project A", "project", false, {id: 5});
    var result = [];
    ysy.saver.linearizeTree(project, null, null, result, true);
    expect(result).toEqual([]);
  });
  it("should return 1 unsafe pack for 1 issue if unsafe", function () {
    var ysy = jasmine.ysyInstance;
    var project = new window.easyMindMupClasses.RootIdea(ysy);
    project.fromServer(5, "Project A", "project", false, {id: 5});
    var issue = new window.easyMindMupClasses.ModelEntity(ysy);
    issue.fromServer(6, "Issue A", "issue", true, {
      id: 6, project_id: 5,
      subject: "Issue A"
    });
    project.ideas = {5: issue};
    var result = [];
    ysy.saver.linearizeTree(project, null, null, result, true);
    expect(result.length).toEqual(1);
    var pack = result[0];
    expect(pack.node).toBe(issue);
    expect(pack.parent).toBe(project);
    expect(pack.isSame).toBe(false);
    expect(pack.isSafe).toBe(false);
  });
  it("should return 0 packs for 1 unchanged issue if safe", function () {
    var ysy = jasmine.ysyInstance;
    var project = new window.easyMindMupClasses.RootIdea(ysy);
    project.fromServer(5, "Project A", "project", false, {id: 5});
    var issue = new window.easyMindMupClasses.ModelEntity(ysy);
    issue.fromServer(6, "Issue A", "issue", true, {
      id: 6, project_id: 5,
      subject: "Issue A"
    });
    project.ideas = {5: issue};
    var result = [];
    ysy.saver.linearizeTree(project, null, null, result, false);
    expect(result.length).toEqual(0);
  });
});