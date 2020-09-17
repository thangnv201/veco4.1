# evms helper.
module EvmsHelper
  include CommonHelper
  # Get project name
  # Add baseline subject when baseline exists
  #
  # @return [String] project name, baseline subject
  def project_chart_name
    chart_title = if @baseline_id.nil?
                    @project.name
                  else
                    @project.name + '- ' + @evmbaseline.find(@baseline_id).subject
                  end
  end
  def getProjectEvm
    if @emv_setting.present?
      # Basis date of calculate
      @cfg_param[:basis_date] = default_basis_date
      # baseline
      @cfg_param[:no_use_baseline] = params[:no_use_baseline]
      @evmbaseline = selectable_baseline_list @project
      @cfg_param[:baseline_id] = default_baseline_id
      # evm explanation
      @cfg_param[:display_explanation] = params[:display_explanation]
      # baseline
      baselines = project_baseline @project, @cfg_param[:baseline_id]
      # issues of project include disendants
      issues = evm_issues @project
      # spent time of project include disendants
      actual_cost = evm_costs @project
      @no_data = issues.blank?
      # calculate EVM
      @project_evm = CalculateEvm.new baselines,
                                      issues,
                                      actual_cost,
                                      @cfg_param
      return @project_evm
    end
  end
end
