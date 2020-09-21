class CnbvKpiController < ApplicationController
  include MyKpiHelper

  $kidanhgia = Project.find(1072).versions.first.id

  def index
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end
    $pmid = 860
    @kpi_raking = PeopleInformation.where(manager_id: $pmid).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    @kpi_raking1 = PeopleKi.where(user_id: users_id, version_id: $kidanhgia)
    sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
    @records_array = ActiveRecord::Base.connection.execute(sql)
    @ki_raking = @records_array.as_json
  end

  def save

    if params[:ki_id] == ""
      uid = PeopleInformation.where(employee_id: params[:user_code]).take.user_id
      PeopleKi.create(:user_id => uid, :version_id => params[:version_id], :location_compliance => params[:location],
                      :labor_rules_compliance => params[:labor_rules], :ki => params[:ki],
                      :manager_note => params[:manage_note], :note => params[:note]);
    else
      PeopleKi.update(params[:ki_id], :location_compliance => params[:location],
                      :labor_rules_compliance => params[:labor_rules], :ki => params[:ki],
                      :manager_note => params[:manage_note], :note => params[:note]);
    end

  end
end
