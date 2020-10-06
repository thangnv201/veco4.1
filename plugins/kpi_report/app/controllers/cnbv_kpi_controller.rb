class CnbvKpiController < ApplicationController
  include MyKpiHelper

  $kidanhgia = Project.find(1072).versions.first.id

  def index
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    $pmid = User.current.id
    $alluser = User.where(status:1).select(:id)
    @kpi_raking = PeopleInformation.where(manager_id: $pmid, user_id:$alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end
  end

  def sub_dep_ki
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    $dids = []
    @department_id = Department.where(head_id: User.current.id)
    @department_id.each do |dep|
      $dids.push(dep.id)
      lft = Department.find(dep.id).lft
      rgt = Department.find(dep.id).rgt
      @ids = Department.where("lft > "+lft.to_s+" and rgt < "+rgt.to_s)
      @ids.each do |obj|
        $dids.push(obj.id)
      end
    end
    $dpid = $dids[0]
    if params.key?("depid")
      $dpid = params["depid"].to_i
    else
      $dpid = $dids[0]
    end
    $alluser = User.where(status:1).where.not(login: User.current.login).select(:id)
    @kpi_raking = PeopleInformation.where(department_id: $dpid, user_id:$alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end
  end

  def dep_ki
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    $dpid = Department.where(head_id: User.current.id).select(:id).map(&:id).uniq
    $alluser = User.where(status:1).where.not(login: User.current.login).select(:id)
    @kpi_raking = PeopleInformation.where(department_id: $dpid, user_id:$alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end
  end

  def TCLD
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    $pmid = PeopleInformation.where.not(manager_id: nil).select(:manager_id).map(&:manager_id).uniq.first
    if params.key?("manager")
      $pmid = params["manager"].to_i
    else
      $pmid = PeopleInformation.where.not(manager_id: nil).select(:manager_id).map(&:manager_id).uniq.first
    end
    $alluser = User.where(status:1).select(:id)
    @kpi_raking = PeopleInformation.where(manager_id: $pmid, user_id:$alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end
  end

  def heads
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    $pmid = DepartmentHead.where.not(head_id: nil).select(:head_id).map(&:head_id).uniq.first
    if params.key?("headid")
      $pmid = params["headid"].to_i
    else
      $pmid = DepartmentHead.where.not(head_id: nil).select(:head_id).map(&:head_id).uniq.first
    end
    $alluser = User.where(status:1).select(:id)
    dids = []
    @department_id = Department.where(head_id: $pmid)
    @department_id.each do |dep|
      dids.push(dep.id)
      lft = Department.find(dep.id).lft
      rgt = Department.find(dep.id).rgt
      @ids = Department.where("lft > "+lft.to_s+" and rgt < "+rgt.to_s)
      @ids.each do |obj|
        dids.push(obj.id)
      end
    end
    @kpi_raking = PeopleInformation.where(department_id: dids, user_id:$alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end
  end

  def heads2
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    $pmid = DepartmentHead.where.not(head_id: nil).select(:head_id).map(&:head_id).uniq.first
    if params.key?("headid")
      $pmid = params["headid"].to_i
    else
      $pmid = DepartmentHead.where.not(head_id: nil).select(:head_id).map(&:head_id).uniq.first
    end
    $alluser = User.where(status:1).select(:id)
    dids = []
    did = DepartmentHead.where(head_id: $pmid).select(:department_id)
    @department_id = Department.where(id: did)
    @department_id.each do |dep|
      dids.push(dep.id)
      lft = Department.find(dep.id).lft
      rgt = Department.find(dep.id).rgt
      @ids = Department.where("lft > "+lft.to_s+" and rgt < "+rgt.to_s)
      @ids.each do |obj|
        dids.push(obj.id)
      end
    end
    @kpi_raking = PeopleInformation.where(department_id: dids, user_id:$alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end
  end

  def save
      uid = PeopleInformation.where(employee_id: params[:user_code]).take.user_id
      check_create = PeopleKi.where(user_id: uid, version_id: params[:version_id]).size
      if check_create > 0
        pkid=PeopleKi.where(user_id: uid, version_id: params[:version_id]).first.id
        PeopleKi.update(pkid, :location_compliance => params[:location], :kpi_type => params[:ki_type],
                        :labor_rules_compliance => params[:labor_rules], :ki => params[:ki],
                        :manager_note => params[:manage_note], :note => params[:note]);
      else
        PeopleKi.create(:user_id => uid, :version_id => params[:version_id],:kpi_type =>params[:ki_type], :location_compliance => params[:location],
                        :labor_rules_compliance => params[:labor_rules], :ki => params[:ki],
                        :manager_note => params[:manage_note], :note => params[:note]);
      end
  end

  def saveRendKI

    objects = params[:obj]
    objects.each do |key, value|
      uid = PeopleInformation.where(employee_id: value["user_code"]).take.user_id
      check_create = PeopleKi.where(user_id: uid, version_id: value["version_id"]).size
      if check_create > 0
        pkid=PeopleKi.where(user_id: uid, version_id: value["version_id"]).first.id
        PeopleKi.update(pkid, :location_compliance => value["location"], :kpi_type => value["ki_type"],
                        :labor_rules_compliance => value["labor_rules"], :ki => value["ki"],
                        :manager_note => value["manage_note"], :note => value["note"]);
      else
        PeopleKi.create(:user_id => uid, :version_id => value["version_id"],:kpi_type =>value["ki_type"], :location_compliance => value["location"],
                        :labor_rules_compliance => value["labor_rules"], :ki => value["ki"],
                        :manager_note => value["manage_note"], :note => value["note"]);
      end
    end
  end

  def tcldsave
    PeopleKiLock.where(lead_id: params[:pmid], version_id: params[:version_id]).update_all(:lead_id => params[:pmid], :version_id => params[:version_id],:status =>params[:status]);
  end

  def saveAllKI
    $alluser = User.where(status:1).select(:id)
    @people_in = PeopleInformation.where(manager_id: User.current.id, user_id:$alluser).order(:user_id)
    users_id = []
    @people_in.each do |kpi|
      users_id.push(kpi.user_id)
    end
    @issues = Issue.where(assigned_to_id:users_id, fixed_version_id:params[:version_id]).where.not(status_id: 35)
    @issues.each do |obj|
      obj.status_id = 36
      obj.save
    end
    check_create = PeopleKiLock.where(lead_id: User.current.id, version_id: params[:version_id]).size
    if check_create > 0
      PeopleKiLock.where(lead_id: User.current.id, version_id: params[:version_id]).update_all(:lead_id => User.current.id, :version_id => params[:version_id],:status =>params[:status]);
    else
      PeopleKiLock.create(:lead_id => User.current.id, :version_id => params[:version_id],:status =>params[:status]);
    end
  end

  def get_user_kpi
    if params.key?("vid")
      $kidanhgia = params[:vid]
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    flash.delete(:notice)
    @kpi_open_dinh_luong = Project.find(1072).issues.where(:assigned_to => params[:uid]).where(:fixed_version_id => $kidanhgia).order("FIELD(status_id,36,34,33,32,29,35)")
    result = total_ti_trong(@kpi_open_dinh_luong, nil)
    @total_ti_trong = result[0]
    @total_cbnv_point = result[1]
    @total_qltt_point = result[2]
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
    if !cbnv_ki.nil?
      cbnv_ki.kpi = qltt_point_total
      cbnv_ki.save
    end
    return [titrong_total, cbnv_point_total, qltt_point_total]
  end
end
