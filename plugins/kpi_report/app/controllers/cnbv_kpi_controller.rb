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
    @kpi_raking = PeopleInformation.where(manager_id: $pmid).order(:user_id)
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
    # $pmid = User.current.id
    @kpi_raking = PeopleInformation.where(manager_id: $pmid).order(:user_id)
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
