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
    @arm                     = Array.new
    @designDetails           = Array.new
    @armDetails              = Array.new
    @baselineCharacteristics = Array.new
    @outcomeDetails          = Array.new
    @keyQuestions            = Array.new
    @primaryPublications     = Array.new

    csv_raw = @csv_raw.blank? ? main : @csv_raw
    csv_raw.each do |row|

      case row[17]
      when "Arm"
        @arm.push row
      when "DesignDetail"
        @designDetails.push row
      when "KeyQuestion"
        @keyQuestions.push row
      when "PrimaryPublication"
        @primaryPublications.push row
      when "ArmDetail"
        @armDetails.push row
      when "BaselineCharacteristic"
        @baselineCharacteristics.push row
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
      row_info[:arm_title]          = r[32]
      row_info[:outcome_id]         = r[33]
      row_info[:outcome_title]      = r[34]

      write_to_db(row_info)
    end
  end

  def process_arm_details
    @armDetails.each do |a|
      row_info = Hash.new

      row_info[:ef_id]              = a[1]
      row_info[:study_id]           = a[3]
      row_info[:section]            = a[17]
      row_info[:type]               = a[18]
      row_info[:datapoint_ID]       = a[19]
      row_info[:dd_id]              = a[20]
      row_info[:datapoint_value]    = a[22]
      row_info[:notes]              = a[23]
      row_info[:subquestion_value]  = a[26]
      row_info[:row_field_id]       = a[27]
      row_info[:column_field_id]    = a[29]
      row_info[:arm_id]             = a[31]
      row_info[:arm_title]          = a[32]
      row_info[:outcome_id]         = a[33]
      row_info[:outcome_title]      = a[34]

      insert_db(section="ArmDetail", info=row_info)
    end
  end

  def process_baseline_characteristics
    @baselineCharacteristics.each do |b|
      row_info = Hash.new

      row_info[:ef_id]              = b[1]
      row_info[:study_id]           = b[3]
      row_info[:section]            = b[17]
      row_info[:type]               = b[18]
      row_info[:datapoint_ID]       = b[19]
      row_info[:dd_id]              = b[20]
      row_info[:datapoint_value]    = b[22]
      row_info[:notes]              = b[23]
      row_info[:subquestion_value]  = b[26]
      row_info[:row_field_id]       = b[27]
      row_info[:column_field_id]    = b[29]
      row_info[:arm_id]             = b[31]
      row_info[:arm_title]          = b[32]
      row_info[:outcome_id]         = b[33]
      row_info[:outcome_title]      = b[34]

      insert_db(section="BaselineCharacteristic", info=row_info)
    end
  end

  def insert_db(section, info)  #{{{2
    params = {:section_detail_id      => info[:dd_id],
              :value                  => "%#{info[:datapoint_value]}%",
              :study_id               => info[:study_id],
              :extraction_form_id     => info[:ef_id],
              :row_field_id           => info[:row_field_id],
              :column_field_id        => info[:column_field_id],
              :arm_id                 => info[:arm_id],
              :outcome_id             => info[:outcome_id]}

    section_field_id_name = "#{info[:section].underscore}_field_id"

    if info[:datapoint_ID].blank?
      p info
      gets
      unless info[:datapoint_value].blank?
        dp = "#{info[:section]}DataPoint".constantize.find(:first, :conditions => ["#{info[:section].underscore}_field_id=:section_detail_id AND value LIKE :value AND study_id=:study_id AND extraction_form_id=:extraction_form_id AND row_field_id=:row_field_id AND column_field_id=:column_field_id AND arm_id=:arm_id AND outcome_id=:outcome_id", params])
        if dp.blank?
          dp = "#{info[:section]}DataPoint".constantize.create("#{info[:section].underscore}_field_id".to_sym => info[:dd_id],
                                                               :value                 => info[:datapoint_value],
                                                               :notes                 => info[:notes],
                                                               :study_id              => info[:study_id],
                                                               :extraction_form_id    => info[:ef_id],
                                                               :subquestion_value     => info[:subquestion_value],
                                                               :row_field_id          => info[:row_field_id],
                                                               :column_field_id       => info[:column_field_id],
                                                               :arm_id                => info[:arm_id],
                                                               :outcome_id            => info[:outcome_id])
        end
        dp.instance_eval(section_field_id_name) = info[:dd_id]
        dp.value                                = info[:datapoint_value]
        dp.subquestion_value                    = info[:subquestion_value]
        dp.notes                                = info[:notes]
        dp.save
      end
    else
      begin
        dp                   = "#{info[:section]}DataPoint".constantize.find(info[:datapoint_ID])
      rescue
        dp                   = "#{info[:section]}DataPoint".constantize.create("#{info[:section].underscore}_field_id".to_sym => info[:dd_id],
                                                                               :value                 => info[:datapoint_value],
                                                                               :notes                 => info[:notes],
                                                                               :study_id              => info[:study_id],
                                                                               :extraction_form_id    => info[:ef_id],
                                                                               :subquestion_value     => info[:subquestion_value],
                                                                               :row_field_id          => info[:row_field_id],
                                                                               :column_field_id       => info[:column_field_id],
                                                                               :arm_id                => info[:arm_id],
                                                                               :outcome_id            => info[:outcome_id])
      ensure
        dp.instance_eval(section_field_id_name) = info[:dd_id]
        dp.value                                = info[:datapoint_value]
        #!!! Need to think about this some more. Is it safe to update these with values taken from the spreadsheet??
        dp.study_id                             = info[:study_id]
        dp.extraction_form_id                   = info[:ef_id]
        ############################################################################################################
        dp.subquestion_value                    = info[:subquestion_value]
        dp.notes                                = info[:notes]
        dp.save
      end
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
        #!!! Need to think about this some more. Is it safe to update these with values taken from the spreadsheet??
        dp.study_id               = info[:study_id]
        dp.extraction_form_id     = info[:ef_id]
        ############################################################################################################
        dp.subquestion_value      = info[:subquestion_value]
        dp.notes                  = info[:notes]
        dp.save
      end
    end
  end
end
