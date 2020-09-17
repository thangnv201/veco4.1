module EasyMindmup

  def self.easy_extensions?
    Redmine::Plugin.installed?(:easy_extensions)
  end

  def self.combine_by_pipeline?(params)
    return false unless easy_extensions?
    return params[:combine_by_pipeline].to_s.to_boolean if params.key?(:combine_by_pipeline)
    Rails.env.production?
  end

end
