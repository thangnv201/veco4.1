class MyKpiController < ApplicationController

  include MyKpiHelper
  self.main_menu = false

  accept_api_auth :status
  $kidanhgia
  $tuanthudiadiemlamviec = [['Tuân thủ', 1], ['Không tuân thủ', 2]]
  $tuanthunoiquylaodong = [['Tuân thủ', 1], ['Vi phạm nhưng chưa đến mức kỉ luật', 2], ['Bị xử lý kỉ luật lao động', 3]]

  def index
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).default_version_id
    end
    flash.delete(:notice)
    @kpi_open_dinh_luong = Project.find(1072).issues.where(:assigned_to => User.current.id)
                               .where(:fixed_version_id => $kidanhgia).order("FIELD(status_id,36,34,33,32,29,35)")
    result = total_ti_trong(@kpi_open_dinh_luong, nil)
    @total_ti_trong = result[0]
    @total_cbnv_point = result[1]
    @total_qltt_point = result[2]
    update_kpi_point(@kpi_open_dinh_luong, User.current.id)
  end

  def update_kpi_point(kpis, user_id)
    if PeopleKi.where(:user_id => user_id).where(:version_id => $kidanhgia).length == 0
      PeopleKi.create(:user_id => user_id, :version_id => $kidanhgia, :location_compliance => 1, :labor_rules_compliance => 1)
    end
    @cbnv_ki = PeopleKi.where(:user_id => user_id).where(:version_id => $kidanhgia).first
    qltt_point_total = 0
    kpis.each do |kpi|
      if (kpi.status_id != 35)
        tytrong = issue_customfield_value(kpi, 139).to_i
        qltt_point = issue_customfield_value(kpi, 141)
        if qltt_point != ""
          qltt_point_total += qltt_point[0, 1].to_i * (tytrong / 100.0)
        end
      end
    end
    @cbnv_ki.kpi = qltt_point_total
    @cbnv_ki.save
  end

  def updatekpipoint
    user_id = params["user"].to_i
    version = params["vid"].to_i
    if PeopleKi.where(:user_id => user_id).where(:version_id => version).length == 0
      PeopleKi.create(:user_id => user_id, :version_id => version, :location_compliance => 1, :labor_rules_compliance => 1)
    end
    cbnv_ki = PeopleKi.where(:user_id => user_id).where(:version_id => version).first
    qltt_point_total = 0
    Project.find(1072).issues.where(:assigned_to => user_id)
        .where.not(:status_id => 35)
        .where(:fixed_version_id => version).each do |kpi|
      tytrong = issue_customfield_value(kpi, 139).to_i
      qltt_point = issue_customfield_value(kpi, 141)
      if qltt_point != ""
        qltt_point_total += qltt_point[0, 1].to_i * (tytrong / 100.0)
      end
    end
    cbnv_ki.kpi = qltt_point_total
    cbnv_ki.save
    render json: cbnv_ki
  end

  def total_ti_trong(kpis, cbnv_ki)
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
    qltt_point_total = qltt_point_total.round(2)
    cbnv_point_total = cbnv_point_total.round(2)

    return [titrong_total, cbnv_point_total, qltt_point_total]
  end

  $cbnv

  def cbnvkpi
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).default_version_id
    end
    @kpi_open_dinh_luong = Project.find(1072).issues.where(:author_id => User.current.id)
                               .where.not(:status_id => 35)
                               .where(:fixed_version_id => $kidanhgia)
    return unless @kpi_open_dinh_luong.length > 0
    @cbnv = @kpi_open_dinh_luong.select(:assigned_to_id).distinct
    if params.key?("cbnv")
      $cbnv = params["cbnv"].to_i
    else
      $cbnv = @cbnv.first.assigned_to_id
    end
    @kpi = @kpi_open_dinh_luong.where(:assigned_to_id => $cbnv).order("FIELD(status_id,36,34,33,32,29,35)")

    @permission_danhgia = get_main_qltt($cbnv, $kidanhgia) == User.current.id ? true : false
    if PeopleKi.where(:user_id => $cbnv).where(:version_id => $kidanhgia).length == 0
      PeopleKi.create(:user_id => $cbnv, :version_id => $kidanhgia, :location_compliance => 1, :labor_rules_compliance => 1)
    end
    if PeopleKiNote.where(:user_id => $cbnv).where(:version_id => $kidanhgia).where(:lead_id => User.current.id).length == 0
      PeopleKiNote.create(:user_id => $cbnv, :version_id => $kidanhgia, :lead_id => User.current.id, :comment => "")
    end
    @cbnv_ki = PeopleKi.where(:user_id => $cbnv).where(:version_id => $kidanhgia).first
    @cbnv_ki_note = PeopleKiNote.where(:user_id => $cbnv).where(:version_id => $kidanhgia).where(:lead_id => User.current.id).first
    result = total_ti_trong(@kpi, @cbnv_ki)
    @total_ti_trong = result[0]
    @total_cbnv_point = result[1]
    @total_qltt_point = result[2]
    flash.delete(:notice)
    respond_to do |format|
      format.html # show.html.erb
    end
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
    qltt_point = issue_customfield_value(@issue, 141)
    @qltt_point = CustomField.find(141).enumerations.map { |a| a.name == qltt_point ? {'value': a.id, 'name': a.name, 'selected': true} : {'value': a.id, 'name': a.name} }
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
    note = @issue.journals.where.not(:notes => "").map { |a| User.find(a.user_id).login + ": " + a.notes }
    data = {
        'note': note.join("\n"),
        'category': @caregory,
        'description': @issue.description,
        'start_date': @issue.start_date,
        'due_date': @issue.due_date,
        'status_id': @issue.status_id
    }
    render json: data
  end

  def get_main_qltt(user_id, version)
    sql = "select author_id,Max(tytrong) as tt from (SELECT  issues.author_id,sum(custom_values.value) as tytrong FROM `issues` inner join custom_values on issues.id = custom_values.customized_id
WHERE `issues`.`project_id` = 1072 AND `issues`.`assigned_to_id` = " + user_id.to_s + " and fixed_version_id=" + version.to_s + " and custom_values.custom_field_id=139 and issues.status_id !=35
group by issues.author_id)   as y"
    result = ActiveRecord::Base.connection.execute(sql);
    return result.as_json.first.first
  end

  def update_people_ki
    location_compliance = 1
    labor_rules_compliance = 1
    cbnv = params[:cbnv].to_i
    kidanhgia = params[:kidanhgia].to_i
    people_ki = PeopleKi.where(:user_id => cbnv).where(:version_id => kidanhgia).first
    people_ki_note = PeopleKiNote.where(:user_id => cbnv).where(:version_id => kidanhgia).where(:lead_id => params[:user]).first
    if params.key?("location_compliance")
      location_compliance = params[:location_compliance].to_i
      people_ki.location_compliance = location_compliance
    end
    if params.key?("labor_rules_compliance")
      labor_rules_compliance = params[:labor_rules_compliance].to_i
      people_ki.labor_rules_compliance = labor_rules_compliance
    end
    if params.key?("nhanxetchung[]")
      note = params["nhanxetchung[]"].to_s
      people_ki_note.comment = note
    end
    if people_ki.save && people_ki_note.save
      render json: people_ki
    else
      render json: "error"
    end
  end

  def importkpi
    if params.key?("user")
      user = params["user"].to_i
    else
      user = User.current.id
    end
    @option = [['Cá nhân: ' + User.find(user).firstname, user]]
    manager = Person.find(user).manager
    @option.push(['Quản lí trực tiếp: ' + manager.login, manager.id]) unless manager.nil?
    @kidanhgia = Project.find(1072).versions.map { |obj| [obj.name, obj.id] }
  end

  def convertkpi
    data = []
    author_id = params["author"] unless params["author"].nil?

    params["issue"].each do |id|
      org_issue = Issue.find(id)
      issue = org_issue.copy
      issue.status_id = 29
      issue.fixed_version_id = params["fixed_version_id"]
      issue.author_id = params["author"].nil? ? org_issue.author_id : params["author"].to_i
      issue.assigned_to_id = params["assignee"].to_i unless params["assignee"].nil?
      kq = IssueCustomField.find_by_name('Chỉ tiêu Thực hiện (KQ)')
      cbnv_point = IssueCustomField.find_by_name('Điểm CBNV tự đánh giá')
      qltt_point = IssueCustomField.find_by_name('Điểm QLTT đánh giá')
      issue.custom_field_values = {kq.id => '', cbnv_point.id => '', qltt_point.id => ''}
      issue.save
      data.push(issue.id)
    end
    render json: data
  end

  def kimodule

  end

  def pa_kpi
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).default_version_id
    end
    flash.delete(:notice)
    @member = find_group_member(User.current.id)
    return unless @member.length > 0
    @user_ql = User.find(@member.first)
    @user_ql = User.find(params["user"].to_i) unless !params.key?("user")
    @kpi_open_dinh_luong = Project.find(1072).issues.where(:assigned_to => @user_ql.id)
                               .where(:fixed_version_id => $kidanhgia).order("FIELD(status_id,36,34,33,32,29,35)")
    result = total_ti_trong(@kpi_open_dinh_luong, nil)
    @total_ti_trong = result[0]
    @total_cbnv_point = result[1]
    @total_qltt_point = result[2]
    update_kpi_point(@kpi_open_dinh_luong, @user_ql.id)
  end

  def pa_cbnv_kpi
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).default_version_id
    end
    @member = find_group_member(User.current.id)
    return unless @member.length > 0
    @user_ql = User.find(@member.first)
    @user_ql = User.find(params["user"].to_i) unless !params.key?("user")
    @kpi_open_dinh_luong = Project.find(1072).issues.where(:author_id => @user_ql.id)
                               .where.not(:status_id => 35)
                               .where(:fixed_version_id => $kidanhgia)
    return unless @kpi_open_dinh_luong.length > 0
    @cbnv = @kpi_open_dinh_luong.select(:assigned_to_id).distinct
    if params.key?("cbnv")
      id = params["cbnv"].to_i
      tmp = @cbnv.find_by(:assigned_to_id => id)
      if !tmp.nil?
        $cbnv = id
      else
        $cbnv = @cbnv.first.assigned_to_id
      end
    else
      $cbnv = @cbnv.first.assigned_to_id
    end
    @kpi = @kpi_open_dinh_luong.where(:assigned_to_id => $cbnv).order("FIELD(status_id,36,34,33,32,29,35)")

    @permission_danhgia = get_main_qltt($cbnv, $kidanhgia) == User.current.id ? true : false
    if PeopleKi.where(:user_id => $cbnv).where(:version_id => $kidanhgia).length == 0
      PeopleKi.create(:user_id => $cbnv, :version_id => $kidanhgia, :location_compliance => 1, :labor_rules_compliance => 1)
    end
    if PeopleKiNote.where(:user_id => $cbnv).where(:version_id => $kidanhgia).where(:lead_id => User.current.id).length == 0
      PeopleKiNote.create(:user_id => $cbnv, :version_id => $kidanhgia, :lead_id => User.current.id, :comment => "")
    end
    @cbnv_ki = PeopleKi.where(:user_id => $cbnv).where(:version_id => $kidanhgia).first
    @cbnv_ki_note = PeopleKiNote.where(:user_id => $cbnv).where(:version_id => $kidanhgia).where(:lead_id => User.current.id).first
    result = total_ti_trong(@kpi, @cbnv_ki)
    @total_ti_trong = result[0]
    @total_cbnv_point = result[1]
    @total_qltt_point = result[2]
    flash.delete(:notice)
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def find_group_member(user_id)
    member = []
    Gmanager.where(:id_owner => User.current.id).each do |group|
      begin
        tmp = Group.find(group.id_group)
      rescue ActiveRecord::RecordNotFound => e
        next
      end
      if tmp.projects.ids.include? 1072
        member += tmp.users.map { |u| u.id }
      end
    end

    return member.uniq
  end

end
