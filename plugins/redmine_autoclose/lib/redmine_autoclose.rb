module RedmineAutoclose
  def self.child_status_id()  Setting[:plugin_redmine_autoclose][:child_status_id].to_i  end
  def self.parent_status_id() Setting[:plugin_redmine_autoclose][:parent_status_id].to_i end
end
