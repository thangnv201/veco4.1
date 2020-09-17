class StatisticController < ApplicationController

  helper :custom_fields
  helper :issues
  helper :queries
  helper :repositories
  helper :members
  helper :trackers


  include ProjectsHelper
  include ReportsHelper

  include IssueDataFetcher
  include BaselineDataFetcher
  include CalculateEvmLogic
  include ChartDataMaker

  def statisticBGD

    hash = []
    user = User.find_by_login(params[:login])
    if getProjectsByUserRoleName(user, "* Chỉ huy trực tiếp").length > 0
      getProjectsByUserRoleName(user, "* Chỉ huy trực tiếp").each do |project|
        obj = {}
        find_common_setting_by_project_id project.id
        if @emv_setting.present?
          # Basis date of calculate
          @cfg_param[:basis_date] = default_basis_date
          # baseline
          @cfg_param[:no_use_baseline] = params[:no_use_baseline]
          @evmbaseline = selectable_baseline_list project
          @cfg_param[:baseline_id] = default_baseline_id
          # evm explanation
          @cfg_param[:display_explanation] = params[:display_explanation]
          # baseline
          baselines = project_baseline project, @cfg_param[:baseline_id]
          # issues of project include disendants
          issues = evm_issues project
          # spent time of project include disendants
          actual_cost = evm_costs project
          @no_data = issues.blank?
          # calculate EVM
          project_evm = CalculateEvm.new baselines,
                                         issues,
                                         actual_cost,
                                         @cfg_param
          obj[:spi] = {'value' => project_evm.today_spi.to_json, 'color' => spi_color(project_evm)}
          obj[:ev] = {'value' => project_evm.complete_ev(@cfg_param[:working_hours]).to_json}
          obj[:sv] = {'value' => project_evm.today_sv(@cfg_param[:working_hours]).to_json}
        end

        cond = project.project_condition(Setting.display_subprojects_issues?)
        obj[:role] = "* Chỉ huy trực tiếp"
        obj[:project] = project
        obj[:deadline] = project.custom_field_value(CustomField.where(:name => "Deadline dự án")[0].id)
        obj[:open_issues_by_tracker] = Issue.visible(user).open.where(cond).group(:tracker).count
        obj[:total_issues_by_tracker] = Issue.visible(user).where(cond).group(:tracker).count
        hash << obj
      end
    elsif getProjectsByUserRoleName(user, "* Chủ nhiệm ĐT/DA").length > 0
      getProjectsByUserRoleName(user, "* Chủ nhiệm ĐT/DA").each do |project|
        obj = {}
        find_common_setting_by_project_id project.id
        if @emv_setting.present?
          # Basis date of calculate
          @cfg_param[:basis_date] = default_basis_date
          # baseline
          @cfg_param[:no_use_baseline] = params[:no_use_baseline]
          @evmbaseline = selectable_baseline_list project
          @cfg_param[:baseline_id] = default_baseline_id
          # evm explanation
          @cfg_param[:display_explanation] = params[:display_explanation]
          # baseline
          baselines = project_baseline project, @cfg_param[:baseline_id]
          # issues of project include disendants
          issues = evm_issues project
          # spent time of project include disendants
          actual_cost = evm_costs project
          @no_data = issues.blank?
          # calculate EVM
          project_evm = CalculateEvm.new baselines,
                                         issues,
                                         actual_cost,
                                         @cfg_param
          obj[:spi] = {'value' => project_evm.today_spi.to_json, 'color' => spi_color(project_evm)}
          obj[:ev] = {'value' => project_evm.complete_ev(@cfg_param[:working_hours]).to_json}
          obj[:sv] = {'value' => project_evm.today_sv(@cfg_param[:working_hours]).to_json}
        end

        cond = project.project_condition(Setting.display_subprojects_issues?)
        obj[:role] = "* Chủ nhiệm ĐT/DA"
        obj[:project] = project
        obj[:deadline] = project.custom_field_value(CustomField.where(:name => "Deadline dự án")[0].id)
        obj[:open_issues_by_tracker] = Issue.visible(user).open.where(cond).group(:tracker).count
        obj[:total_issues_by_tracker] = Issue.visible(user).where(cond).group(:tracker).count
        hash << obj
      end
    end
    respond_to do |format|
      format.json {
        render json: hash
      }
    end
  end


  def find_common_setting_by_project_id id
    # check view setting
    @emv_setting = Evmsetting.find_by(project_id: id)
    @cfg_param = {}
    return if @emv_setting.blank?

    # plugin setting: chart
    @cfg_param[:display_performance] = @emv_setting.view_performance
    @cfg_param[:display_incomplete] = @emv_setting.view_issuelist
    # plugin setting: chart and EVM value table
    @cfg_param[:forecast] = @emv_setting.view_forecast
    @cfg_param[:limit_spi] = @emv_setting.threshold_spi
    @cfg_param[:limit_cpi] = @emv_setting.threshold_cpi
    @cfg_param[:limit_cr] = @emv_setting.threshold_cr
    # plugin setting: calculation evm
    @cfg_param[:calcetc] = @emv_setting.etc_method
    @cfg_param[:working_hours] = @emv_setting.basis_hours
    # plugin setting: holyday region
    @cfg_param[:exclude_holiday] = @emv_setting.exclude_holidays
    @cfg_param[:region] = @emv_setting.region
  end

  private

  # default basis date
  #
  def default_basis_date
    params[:basis_date].nil? ? Time.zone.today : params[:basis_date].to_date
  end

  # default baseline. latest baseline
  #
  def default_baseline_id
    if params[:evmbaseline_id].nil?
      @evmbaseline.blank? ? nil : @evmbaseline.first.id
    else
      params[:evmbaseline_id]
    end
  end

  # SPI color of CSS.
  #
  # @return [String] SPI color
  def spi_color(evm)
    value = case evm.today_spi
            when (@cfg_param[:limit_spi] + 0.01..0.99)
              "#f0ad4e" #warning
            when (0.01..@cfg_param[:limit_spi])
              "#d9534f" #danger
            else
              ""
              "#5cb85c" #good
            end
    value.html_safe
  end

  # CPI color of CSS.
  #
  # @return [String] CPI color
  def cpi_color(evm)
    value = case evm.today_cpi
            when (@cfg_param[:limit_cpi] + 0.01..0.99)
              "#f0ad4e" #warning
            when (0.01..@cfg_param[:limit_cpi])
              "#d9534f" #danger
            else
              "#5cb85c" #good
            end
    value.html_safe
  end
end
