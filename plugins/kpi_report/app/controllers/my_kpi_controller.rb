class MyKpiController < ApplicationController

  include MyKpiHelper
  self.main_menu = false

  accept_api_auth :status
  $kidanhgia = Project.find(1072).versions.first.id
  $test = "thang"

  def index
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    flash.delete(:notice)
    @kpi_open_dinh_luong = Project.find(1072).issues.where(:assigned_to => User.current.id)
                               .where(:fixed_version_id => $kidanhgia).order("FIELD(status_id,36,34,33,32,29,35)")
    result = total_ti_trong(@kpi_open_dinh_luong)
    @total_ti_trong = result[0]
    @total_cbnv_point = result[1]
    @total_qltt_point = result[2]

  end

  def total_ti_trong(kpis)
    titrong_total = 0
    cbnv_point_total = 0
    qltt_point_total = 0
    kpis.each do |kpi|
      if (kpi.status_id != 35)
        tytrong = issue_customfield_value(kpi, 139).to_i
        titrong_total += tytrong
        cbnv_point = issue_customfield_value(kpi, 140)
        if cbnv_point != ""
          cbnv_point_total += cbnv_point[0, 1].to_i * (tytrong / 100.0)
        end
        qltt_point = issue_customfield_value(kpi, 141)
        if qltt_point != ""
          qltt_point_total += qltt_point[0, 1].to_i * (tytrong / 100.0)
        end
      end
    end
    return [titrong_total, cbnv_point_total, qltt_point_total]
  end

  $cbnv

  def cbnvkpi
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    @kpi_open_dinh_luong = Project.find(1072).issues.where(:author_id => User.current.id)
                               .where(:fixed_version_id => $kidanhgia)
    @cbnv = @kpi_open_dinh_luong.select(:assigned_to_id).distinct
    if params.key?("cbnv")
      $cbnv = params["cbnv"].to_i
    else
      $cbnv = @cbnv.first.assigned_to_id
    end
    @kpi = @kpi_open_dinh_luong.where(:assigned_to_id => $cbnv).order("FIELD(status_id,36,34,33,32,29,35)")
    result = total_ti_trong(@kpi)
    @total_ti_trong = result[0]
    @total_cbnv_point = result[1]
    @total_qltt_point = result[2]
    flash.delete(:notice)

  end

  def status
    @issue = Issue.find(params[:id])
    @status = @issue.new_statuses_allowed_to(User.find(params[:user_id]))
                  .map { |a| a.id == @issue.status_id ? {'value': a.id, 'name': a.name, 'selected': true} : {'value': a.id, 'name': a.name} }
    if @status.count == 0
      @status = [{'value': @issue.status.id, 'name': @issue.status.name, 'selected': true}]
    end
    @assinee = @issue.assignable_users
                   .map { |a| a.id == @issue.assigned_to.id ? {'value': a.id, 'name': a.login, 'selected': true} : {'value': a.id, 'name': a.login} }
    @version = @issue.assignable_versions
                   .map { |a| a.id == @issue.fixed_version.id ? {'value': a.id, 'name': a.name, 'selected': true} : {'value': a.id, 'name': a.name} }
    donvido = issue_customfield_value(@issue, 138)
    @donvido = CustomField.find(138).enumerations.map { |a| a.name == donvido ? {'value': a.id, 'name': a.name, 'selected': true} : {'value': a.id, 'name': a.name} }
    cbnv_point = issue_customfield_value(@issue, 140)
    @cbnv_point = CustomField.find(140).enumerations.map { |a| a.name == cbnv_point ? {'value': a.id, 'name': a.name, 'selected': true} : {'value': a.id, 'name': a.name} }
    @qltt_point = CustomField.find(141).enumerations.map { |a| {'value': a.id, 'name': a.name} }
    @tracker = Project.find(1072).trackers.map { |a| a.id == @issue.tracker_id ? {'value': a.id, 'name': a.name, 'selected': true} : {'value': a.id, 'name': a.name} }
    data = {
        'status': @status,
        'assignee': @assinee,
        'version': @version,
        'don_vi_do': @donvido,
        'cbnv_point': @cbnv_point,
        'qltt_point': @qltt_point,
        'author': @issue.author_id,
        'tracker': @tracker,
        'subject': @issue.subject,
        'ti_trong': issue_customfield_value(@issue, 139),
        'muc_tieu': issue_customfield_value(@issue, 1),
        'ly_do_huy': issue_customfield_value(@issue, 47),
        'toithieu': @issue.tracker_id == 39 ? issue_customfield_value(@issue, 142) : @issue.tracker_id == 40 ? issue_customfield_value(@issue, 146) : issue_customfield_value(@issue, 158),
        'mongdoi': @issue.tracker_id == 39 ? issue_customfield_value(@issue, 143) : @issue.tracker_id == 40 ? issue_customfield_value(@issue, 147) : issue_customfield_value(@issue, 159),
        'thachthuc': @issue.tracker_id == 39 ? issue_customfield_value(@issue, 144) : @issue.tracker_id == 40 ? issue_customfield_value(@issue, 148) : issue_customfield_value(@issue, 160),
        'ketqua': @issue.tracker_id == 39 ? issue_customfield_value(@issue, 145) : @issue.tracker_id == 40 ? issue_customfield_value(@issue, 149) : issue_customfield_value(@issue, 151),
    }
    render json: data
  end

  def get_another_field
    @user = User.find(params[:user_id])
    @issue = Issue.find(params[:id])
    @caregory = @issue.project.issue_categories
                    .map { |a| a.id == (@issue.category.nil? ? "" : @issue.category.id) ? {'value': a.id, 'name': a.name, 'selected': true} : {'value': a.id, 'name': a.name} }
    note = @issue.journals.where.not(:notes => "").map { |a| {"user": User.find(a.user_id).login, "note": a.notes} }
    data = {
        'note':note,
        'category': @caregory,
        'description': @issue.description,
        'start_date': @issue.start_date,
        'due_date': @issue.due_date,
    }
    render json: data
  end
end
