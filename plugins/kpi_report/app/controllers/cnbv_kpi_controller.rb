class CnbvKpiController < ApplicationController
  include MyKpiHelper

  $kidanhgia = Project.find(1072).versions.first.id

  def index
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    # $pmid = User.current.id
    $pmid = 860
    @kpi_raking = PeopleInformation.where(manager_id: $pmid).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
    end

  end

  def save
      uid = PeopleInformation.where(employee_id: params[:user_code]).take.user_id
      check_create = PeopleKi.where(user_id: uid, version_id: params[:version_id]).size
      if check_create > 0
        pkid=PeopleKi.where(user_id: uid, version_id: params[:version_id]).first.id
        PeopleKi.update(pkid, :location_compliance => params[:location],
                        :labor_rules_compliance => params[:labor_rules], :ki => params[:ki],
                        :manager_note => params[:manage_note], :note => params[:note]);
      else
        PeopleKi.create(:user_id => uid, :version_id => params[:version_id], :location_compliance => params[:location],
                        :labor_rules_compliance => params[:labor_rules], :ki => params[:ki],
                        :manager_note => params[:manage_note], :note => params[:note]);
      end
  end
end
