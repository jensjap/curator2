#encoding: utf-8

require 'csv'

class Importer  #{{{1

  def initialize(file)  #{{{2
    @file = file
  end

  def main  #{{{2
    @csv_raw = CSV.read(@file, encoding: "ISO8859-1")
  end

  def sort  #{{{2
    @designDetails           = Array.new
    @armDetails              = Array.new
    @baselineCharacteristics = Array.new
    @outcomeDetails          = Array.new
    @keyQuestion             = Array.new
    @primaryPublication      = Array.new
    @arm                     = Array.new

    csv_raw = @csv_raw.blank? ? main : @csv_raw
    csv_raw.each do |row|

      case row[17]
      when "Arm"
        @arm.push row
      when "DesignDetail"
        @designDetails.push row
      when "KeyQuestion"
        @keyQuestion.push row
      when "PrimaryPublication"
        @primaryPublication.push row
      end

    end
  end

  def process_arms  #{{{2
    @arm.each do |a|
      row_info = Hash.new

      row_info[:section]     = a[17]  # R
      row_info[:arm_title]   = a[22]  # W
      row_info[:description] = a[23]  # X
      row_info[:study_id]    = a[24]  # Y
      row_info[:ef_id]       = a[25]  # Z

      _process_arm_for_study(row_info)
      puts "studyID: #{row_info[:study_id]}; section: #{row_info[:section]}; arm_title: #{row_info[:arm_title]}"
    end
  end

  def _process_arm_for_study(row_info)  #{{{2
    arm = Arm.find(:first, :conditions => { :study_id           => row_info[:study_id],
                                            :title              => row_info[:arm_title],
                                            :extraction_form_id => row_info[:ef_id] })
    if arm.blank?
      Arm.create(:study_id              => row_info[:study_id],
                 :title                 => row_info[:arm_title],
                 :description           => row_info[:description],
                 :extraction_form_id    => row_info[:ef_id],
                 :is_suggested_by_admin => 0,
                 :is_intention_to_treat => 1)
    end
  end

  def process_design_details  #{{{2
    @designDetails.each do |r|
      row_info = Hash.new

      row_info[:ef_id]              = r[1]
      row_info[:study_id]           = r[3]
      row_info[:section]            = r[17]
      row_info[:type]               = r[18]
      row_info[:datapoint_ID]       = r[19]
      row_info[:dd_id]              = r[20]
      row_info[:datapoint_value]    = r[22]
      row_info[:notes]              = r[23]
      row_info[:subquestion_value]  = r[26]
      row_info[:row_field_id]       = r[27]
      row_info[:column_field_id]    = r[29]
      row_info[:arm_id]             = r[31]
      row_info[:outcome_id]         = r[32]

      write_to_db(row_info)
    end
  end

  def _find_choice_dd(info)  #{{{2
    params = {:design_detail_id       => info[:dd_id],
              :value                  => "%#{info[:datapoint_value]}%",
              :study_id               => info[:study_id],
              :extraction_form_id     => info[:ef_id],
              :row_field_id           => info[:row_field_id],
              :column_field_id        => info[:column_field_id],
              :arm_id                 => info[:arm_id],
              :outcome_id             => info[:outcome_id]}

    return "#{info[:section]}Field".constantize.find(:first, :conditions => ["design_detail_id=:design_detail_id AND option_text LIKE :value", params])
  end

  def write_to_db(info)  #{{{2
    params = {:design_detail_id       => info[:dd_id],
              :value                  => "%#{info[:datapoint_value]}%",
              :study_id               => info[:study_id],
              :extraction_form_id     => info[:ef_id],
              :row_field_id           => info[:row_field_id],
              :column_field_id        => info[:column_field_id],
              :arm_id                 => info[:arm_id],
              :outcome_id             => info[:outcome_id]}

    if info[:datapoint_ID].blank?
      unless info[:datapoint_value].blank?
        dp = "#{info[:section]}DataPoint".constantize.find(:first, :conditions => ["design_detail_field_id=:design_detail_id AND value LIKE :value AND study_id=:study_id AND extraction_form_id=:extraction_form_id AND row_field_id=:row_field_id AND column_field_id=:column_field_id AND arm_id=:arm_id AND outcome_id=:outcome_id", params])
        if dp.blank?
          dp = "#{info[:section]}DataPoint".constantize.create(design_detail_field_id: info[:dd_id],
                                                               value:                  info[:datapoint_value],
                                                               notes:                  info[:notes],
                                                               study_id:               info[:study_id],
                                                               extraction_form_id:     info[:ef_id],
                                                               subquestion_value:      info[:subquestion_value],
                                                               row_field_id:           info[:row_field_id],
                                                               column_field_id:        info[:column_field_id],
                                                               arm_id:                 info[:arm_id],
                                                               outcome_id:             info[:outcome_id])
        end
        dp.design_detail_field_id = info[:dd_id]
        dp.value                  = info[:datapoint_value]
        dp.subquestion_value      = info[:subquestion_value]
        dp.notes                  = info[:notes]
        dp.save
      end
    else
      begin
        dp                   = "#{info[:section]}DataPoint".constantize.find(info[:datapoint_ID])
      rescue
        dp                   = "#{info[:section]}DataPoint".constantize.create(design_detail_field_id: info[:dd_id],
                                                                               value:                  info[:datapoint_value],
                                                                               notes:                  info[:notes],
                                                                               study_id:               info[:study_id],
                                                                               extraction_form_id:     info[:ef_id],
                                                                               subquestion_value:      info[:subquestion_value],
                                                                               row_field_id:           info[:row_field_id],
                                                                               column_field_id:        info[:column_field_id],
                                                                               arm_id:                 info[:arm_id],
                                                                               outcome_id:             info[:outcome_id])
      ensure
        dp.design_detail_field_id = info[:dd_id]
        dp.value                  = info[:datapoint_value]
        dp.subquestion_value      = info[:subquestion_value]
        dp.notes                  = info[:notes]
        dp.save
      end
    end
  end
end
