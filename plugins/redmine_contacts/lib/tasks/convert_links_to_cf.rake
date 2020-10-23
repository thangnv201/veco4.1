namespace :redmine do
  namespace :contacts do

    desc <<-END_DESC
Convert linked issues for deals and contacts to custom fields

  rake redmine:contacts:convert_links_to_custom_fields RAILS_ENV="production"
END_DESC

    task :convert_links_to_custom_fields => :environment do
      class DealsIssue < ActiveRecord::Base; end
      class ContactsIssue < ActiveRecord::Base; end

      deals_cf = CustomField.new_subclass_instance('IssueCustomField')
      deals_cf.safe_attributes = { name: 'Related deals (converted)',
                                   field_format: 'deal',
                                   is_for_all: true,
                                   multiple: true }

      contacts_cf = CustomField.new_subclass_instance('IssueCustomField')
      contacts_cf.safe_attributes = { name: 'Related contacts (converted)',
                                      field_format: 'contact',
                                      is_for_all: true,
                                      multiple: true }

      deals_cf.tracker_ids = Tracker.pluck(:id)
      contacts_cf.tracker_ids = Tracker.pluck(:id)
      deals_cf.save!
      contacts_cf.save!

      DealsIssue.where("1=1").each do |deal_issue|
        deals_cf.custom_values.create(customized_type: Issue,
                                      customized_id: deal_issue.issue_id,
                                      value: deal_issue.deal_id)
      end

      ContactsIssue.where("1=1").each do |contact_issue|
        contacts_cf.custom_values.create(customized_type: Issue,
                                         customized_id: contact_issue.issue_id,
                                         value: contact_issue.contact_id)
      end
    end
  end
end
