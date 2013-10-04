class MyStudy  #{{{1

  def initialize(project_id, project_info, ef_id, study_id)  #{{{2
    @project_id   = project_id
    @project_info = project_info
    @ef_id        = ef_id
    @study_id     = study_id
  end

  ## Puts together a list of key question IDs that are addressed by the given study ID
  ## Integer -> (listOf KeyQuestionIDs)
  def print_main  #{{{2

    ## KEY QUESTIONS SECTION
    ########################
    listOfkqIDs = get_listOfkqIDs
    listOfkqIDs.each do |kq_id|
      output = "#{common_info}#{key_question_info(kq_id)}"
      puts output
    end

    ## PUBLICATIONS SECTION
    #######################
    output = "#{common_info}#{publication_info}"
    puts output

    ## DESIGN DETAILS SECTION
    #########################
    lof_design_detail_IDs = return_lof_section_detail_IDs(section="DesignDetail")
    lof_design_detail_IDs.each do |dd_id|
      design_detail_info(dd_id)
    end

    ## ARMS SECTION
    ###############
    lof_arm_IDs = get_listOfArmIDs(@study_id)
    lof_arm_IDs.each do |arm_id|
      arm_info(arm_id)
    end

    ## ARM DETAILS SECTION
    #######################
    listOfarmIDs = get_listOfArmIDs(@study_id)
    listOfarmIDs.each do |arm_id|
      listOfArmDetailIDs = return_lof_section_detail_IDs(section="ArmDetail")
      listOfArmDetailIDs.each do |ad_id|
        section_detail_info(arm_id=arm_id, outcome_id=0, section_detail_id=ad_id, section="ArmDetail")
      end
    end

    ## BASELINE CHARACTERISTICS SECTION
    ###################################
    listOfarmIDs = get_listOfArmIDs(@study_id)

    # Baseline characteristics also has this thing where it records an "All Arms (Total)". This is represented with arm_id=0
    listOfarmIDs.push 0

    listOfarmIDs.each do |arm_id|
      listOfBaselineCharacteristicIDs = return_lof_section_detail_IDs(section="BaselineCharacteristic")
      listOfBaselineCharacteristicIDs.each do |bc_id|
        section_detail_info(arm_id=arm_id, outcome_id=0, section_detail_id=bc_id, section="BaselineCharacteristic")
      end
    end

    ## OUTCOMES SECTION
    ###################
    lof_outcome_IDs = get_listOfOutcomeIDs(@study_id)
    lof_outcome_IDs.each do |outcome_id|
      outcome_info(outcome_id)
    end

    ## OUTCOME DETAILS SECTION
    #######################
    listOfoutcomeIDs = get_listOfOutcomeIDs(@study_id)
    listOfoutcomeIDs.each do |outcome_id|
      listOfOutcomeDetailIDs = return_lof_section_detail_IDs(section="OutcomeDetail")
      listOfOutcomeDetailIDs.each do |oc_id|
        section_detail_info(arm_id=0, outcome_id=outcome_id, section_detail_id=oc_id, section="OutcomeDetail")
      end
    end

  end

  def get_listOfkqIDs  #{{{2
    listOfkqIDs = Array.new
  
    study_key_questions = StudyKeyQuestion.find_all_by_study_id(@study_id)
    study_key_questions.each do |s|
      listOfkqIDs.push s.key_question_id
    end
    return listOfkqIDs
  end

  def return_lof_section_detail_IDs(section)  #{{{2
    lof_section_detail_IDs = Array.new

    section_details = "#{section}".constantize.find(:all, :conditions => { extraction_form_id: @ef_id })
    section_details.each do |s|
      lof_section_detail_IDs.push s.id
    end

    return lof_section_detail_IDs
  end

  ## Puts together a list of design detail IDs. These are the IDs of the design detail questions on the given extraction form
  ## Integer -> (listOf DesignDetailIDs)
  def get_listOfddIDs  #{{{2
    listOfddIDs = Array.new

    design_details = DesignDetail.find_all_by_extraction_form_id(@ef_id)
    design_details.each do |d|
      listOfddIDs.push d.id
    end
    return listOfddIDs
  end

  def section_detail_info(arm_id, outcome_id, section_detail_id, section)  #{{{2
    section_detail = "#{section}".constantize.find(section_detail_id)
    
    case section_detail.field_type
    when /text/
      _build_text_row(section=section, section_detail_id=section_detail_id, arm_id=arm_id, outcome_id=outcome_id)
    when /matrix_radio/
      _build_matrix_radio(section=section, section_detail_id=section_detail_id, arm_id=arm_id, outcome_id=outcome_id)
    when /matrix_checkbox/
      #puts "Found a #{section_detail.field_type} question in the #{section} section"
    when /matrix_select/
      _build_matrix_select(section=section, section_detail_id=section_detail_id, arm_id=arm_id, outcome_id=outcome_id)
    else # select, radio, checkbox
      #puts "Found a #{section_detail.field_type} question in the #{section} section"
    end
  end

  def arm_info(arm_id)  #{{{2
    output = ",,,,,,,,,,,,,,,,,"\
             "Arm,,,,,"\
             "\"#{_escape_text(Arm.find(arm_id).title)}\",,"\
             "#{@study_id},"\
             "#{@ef_id}"
    puts output
  end

  def outcome_info(outcome_id)  #{{{2
    output = ",,,,,,,,,,,,,,,,,"\
             "Outcome,,,,,"\
             "\"#{_escape_text(Outcome.find(outcome_id).title)}\",,"\
             "#{@study_id},"\
             "#{@ef_id}"
    puts output
  end

  def get_listOfOutcomeIDs(study_id)  #{{{2
    listOf_outcomeIDs = Array.new

    outcomes = Outcome.find(:all, :conditions => { study_id: study_id})
    outcomes.each do |a|
      listOf_outcomeIDs.push a.id
    end

    return listOf_outcomeIDs
  end

  def get_listOfArmIDs(study_id)  #{{{2
    listOf_armIDs = Array.new

    arms = Arm.find(:all, :conditions => { study_id: study_id})
    arms.each do |a|
      listOf_armIDs.push a.id
    end

    return listOf_armIDs
  end

  def common_info  #{{{2
    pp = PrimaryPublication.find_by_study_id(@study_id)
    if pp.nil?
      pp = PrimaryPublication.create(study_id: @study_id)
    end

    ppn = PrimaryPublicationNumber.find_by_primary_publication_id(pp.id)
    if ppn.nil?
      ppn = PrimaryPublicationNumber.create(primary_publication_id: pp.id)
    end

    output = "#{@project_id}"\
             ",#{@ef_id}"\
             ",\"#{_escape_text(ExtractionForm.find(@ef_id).title)}\""\
             ",#{@study_id}"\
             ",#{pp.id}"\
             ",\"#{_escape_text(pp.title)}\""\
             ",\"#{_escape_text(pp.author)}\""\
             ",\"#{_escape_text(pp.country)}\""\
             ",#{pp.year}"\
             ",#{pp.pmid}"\
             ",\"#{_escape_text(pp.journal)}\""\
             ",#{pp.volume}"\
             ",#{pp.issue}"\
             ",\"#{_escape_text(pp.trial_title)}\""\
             ",#{ppn.id}"\
             ",#{ppn.number}"\
             ",\"#{_escape_text(ppn.number_type)}\""
    return output
  end

  def key_question_info(kq_id)  #{{{2
    output = ",KeyQuestion"\
             ",#{kq_id}"\
             ",#{KeyQuestion.find(kq_id).question_number}"\
             ",\"#{_escape_text(KeyQuestion.find(kq_id).question)}\""
    return output
  end

  def publication_info  #{{{2
    output = ",PrimaryPublication"
    return output
  end

  def design_detail_info(dd_id)  #{{{2
    design_detail = DesignDetail.find(dd_id)

    if design_detail.field_type == "text"
      _build_text_row(section="DesignDetail", section_detail_id=dd_id, arm_id=0, outcome_id=0)
    elsif design_detail.field_type.include?('matrix_radio')
      _build_dd_matrix_radio(dd_id)
    elsif design_detail.field_type.include?('matrix_checkbox')
      _build_dd_matrix_checkbox(dd_id)
    elsif design_detail.field_type.include?('matrix_select')
      _build_dd_matrix_select(dd_id)
    else # select, radio, checkbox
      ## These are any questions that only have 1 column for answer options
      ## Single choice radio button questions (radio), drop-down (select) and
      ## single column multiple choice (aka. checkbox) fall under this category
      _build_dd_one_column(dd_id)
    end
  end

  def _build_text_row(section, section_detail_id, arm_id, outcome_id)  #{{{2
    #dddp = "#{section}DataPoint".constantize.find_by_design_detail_field_id_and_study_id_and_extraction_form_id(dd_id, @study_id, @ef_id)
    dddp = "#{section}DataPoint".constantize.find(:first, :conditions => { :"#{section.underscore}_field_id" => section_detail_id,
                                                                           :study_id                         => @study_id,
                                                                           :extraction_form_id               => @ef_id,
                                                                           :arm_id                           => arm_id,
                                                                           :outcome_id                       => outcome_id })

    if dddp.blank?
      dddp = "#{section}DataPoint".constantize.new(:"#{section.underscore}_field_id" => section_detail_id,
                                                   :study_id                         => @study_id,
                                                   :extraction_form_id               => @ef_id,
                                                   :arm_id                           => arm_id,
                                                   :outcome_id                       => outcome_id)
    end

    _print_csv_line(section=section, dd_id=section_detail_id, dddp=dddp)
  end

  def _build_dd_matrix_checkbox(dd_id)  #{{{2
    ddf_rows = DesignDetailField.find_all_by_design_detail_id_and_column_number(dd_id, 0)
    ddf_cols = DesignDetailField.find_all_by_design_detail_id_and_row_number(dd_id, 0)
    
    find_dddp_matrix_checkbox(dd_id, ddf_rows, ddf_cols)
  end

  def _build_dd_matrix_select(dd_id)  #{{{2
    ## This cannot return nil (I think)
    ddf_rows = DesignDetailField.find_all_by_design_detail_id_and_column_number(dd_id, 0)
    ddf_cols = DesignDetailField.find_all_by_design_detail_id_and_row_number(dd_id, 0)

    ## find_dddp_matrix_select also takes care of printing the csv line
    find_dddp_matrix_select(dd_id, ddf_rows, ddf_cols)
  end

  def _build_dd_matrix_radio(dd_id)  #{{{2
    ## This cannot return nil (I think)
    ddf_rows = DesignDetailField.find_all_by_design_detail_id_and_column_number(dd_id, 0)
    ddf_cols = DesignDetailField.find_all_by_design_detail_id_and_row_number(dd_id, 0)

    ## find_dddp_matrix_radio also takes care of printing the csv line
    find_dddp_matrix_radio(dd_id, ddf_rows, ddf_cols)
  end

  def _build_matrix_select(section, section_detail_id, arm_id, outcome_id)  #{{{2
    ## This cannot return nil (I think)
    section_field_rows = "#{section}Field".constantize.find(:all, :conditions => { "#{section.underscore}_id".to_sym => section_detail_id,
                                                                                   :column_number                    => 0 })
    section_field_cols = "#{section}Field".constantize.find(:all, :conditions => { "#{section.underscore}_id".to_sym => section_detail_id,
                                                                                   :row_number                       => 0 })

    ## find_dp_matrix_radio also takes care of printing the csv line
    find_dp_matrix_select(section=section, section_detail_id=section_detail_id, rows=section_field_rows, cols=section_field_cols, arm_id=arm_id, outcome_id=outcome_id)
  end

  def _build_matrix_radio(section, section_detail_id, arm_id, outcome_id)  #{{{2
    ## This cannot return nil (I think)
    section_field_rows = "#{section}Field".constantize.find(:all, :conditions => { "#{section.underscore}_id".to_sym => section_detail_id,
                                                                                   :column_number                    => 0 })
    section_field_cols = "#{section}Field".constantize.find(:all, :conditions => { "#{section.underscore}_id".to_sym => section_detail_id,
                                                                                   :row_number                       => 0 })

    ## find_dp_matrix_radio also takes care of printing the csv line
    find_dp_matrix_radio(section=section, section_detail_id=section_detail_id, rows=section_field_rows, cols=section_field_cols, arm_id=arm_id, outcome_id=outcome_id)
  end

  def find_dp_matrix_select(section, section_detail_id, rows, cols, arm_id, outcome_id)  #{{{2
    rows.each do |row|
      if row.row_number == -1
        dddp = "#{section}DataPoint".constantize.find(:first, :conditions => { "#{section.underscore}_field_id".to_sym => section_detail_id,
                                                                               :study_id                               => @study_id,
                                                                               :extraction_form_id                     => @ef_id,
                                                                               :arm_id                                 => arm_id,
                                                                               :outcome_id                             => outcome_id,
                                                                               :row_field_id                           => row.id })
        if dddp.blank?
          dddp = "#{section}DataPoint".constantize.new("#{section.underscore}_field_id".to_sym => section_detail_id,
                                           :study_id                               => @study_id,
                                           :extraction_form_id                     => @ef_id,
                                           :row_field_id                           => row.id,
                                           :column_field_id                        => 0,
                                           :arm_id                                 => arm_id,
                                           :outcome_id                             => outcome_id)
        end
  
        _print_csv_line(section, section_detail_id, dddp)
      else
        cols.each do |col|
          listOf_dropdown_options = _find_lof_matrix_select_dropdown_options(section, row.id, col.id)
          dddp = "#{section}DataPoint".constantize.find(:first, :conditions => { "#{section.underscore}_field_id".to_sym => section_detail_id,
                                                                                 :study_id                               => @study_id,
                                                                                 :extraction_form_id                     => @ef_id,
                                                                                 :arm_id                                 => arm_id,
                                                                                 :outcome_id                             => outcome_id,
                                                                                 :row_field_id                           => row.id,
                                                                                 :column_field_id                        => col.id })
          if dddp.blank?
            dddp = "#{section}DataPoint".constantize.new("#{section.underscore}_field_id".to_sym => section_detail_id,
                                             :study_id                               => @study_id,
                                             :extraction_form_id                     => @ef_id,
                                             :row_field_id                           => row.id,
                                             :column_field_id                        => col.id,
                                             :arm_id                                 => arm_id,
                                             :outcome_id                             => outcome_id)
          end
  
          _print_csv_line(section, section_detail_id, dddp)
        end
      end
    end
  end

  def find_dp_matrix_radio(section, section_detail_id, rows, cols, arm_id, outcome_id)  #{{{2
    rows.each do |row|
      if row.row_number == -1
        dddp = "#{section}DataPoint".constantize.find(:first, :conditions => { "#{section.underscore}_field_id".to_sym => section_detail_id,
                                                                               :study_id                               => @study_id,
                                                                               :extraction_form_id                     => @ef_id,
                                                                               :arm_id                                 => arm_id,
                                                                               :outcome_id                             => outcome_id,
                                                                               :row_field_id                           => row.id })
        if dddp.blank?
          dddp = "#{section}DataPoint".constantize.new("#{section.underscore}_field_id".to_sym => section_detail_id,
                                                       :study_id                               => @study_id,
                                                       :extraction_form_id                     => @ef_id,
                                                       :row_field_id                           => row.id,
                                                       :column_field_id                        => 0,
                                                       :arm_id                                 => arm_id,
                                                       :outcome_id                             => outcome_id)
        end
  
        _print_csv_line(section, section_detail_id, dddp)
      else
        # Flag to see if there was any choice found for this row
        any_choice_found = false

        cols.each do |col|
          dddp = "#{section}DataPoint".constantize.find(:first, :conditions => { "#{section.underscore}_field_id".to_sym => section_detail_id,
                                                                                 :value                                  => col.option_text,
                                                                                 :study_id                               => @study_id,
                                                                                 :extraction_form_id                     => @ef_id,
                                                                                 :row_field_id                           => row.id,
                                                                                 :arm_id                                 => arm_id,
                                                                                 :outcome_id                             => outcome_id })
          unless dddp.blank?
            any_choice_found = true
            _print_csv_line(section=section, dd_id=section_detail_id, dddp=dddp)
          end
        end

        if any_choice_found == false
          dddp = "#{section}DataPoint".constantize.new("#{section.underscore}_field_id".to_sym => section_detail_id,
                                                       :study_id                               => @study_id,
                                                       :extraction_form_id                     => @ef_id,
                                                       :row_field_id                           => row.id,
                                                       :column_field_id                        => 0,
                                                       :arm_id                                 => arm_id,
                                                       :outcome_id                             => outcome_id)
          _print_csv_line(section=section, dd_id=section_detail_id, dddp=dddp)
        end
      end
    end
  end

  def _build_dd_one_column(dd_id)  #{{{2
    ## This cannot return nil (I think)
    ddf = DesignDetailField.find_all_by_design_detail_id(dd_id)

    field_type = DesignDetail.find(dd_id).field_type

    if field_type == "checkbox"
      ddf.each do |d|
        dddp = DesignDetailDataPoint.find_by_design_detail_field_id_and_value_and_study_id_and_extraction_form_id(dd_id,
                                                                                                                  d.option_text,
                                                                                                                  @study_id,
                                                                                                                  @ef_id)
        if dddp.blank?
          dddp = DesignDetailDataPoint.new(design_detail_field_id: dd_id,
                                           study_id: @study_id,
                                           extraction_form_id: @ef_id,
                                           row_field_id: 0,
                                           column_field_id: 0,
                                           arm_id: 0,
                                           outcome_id: 0)
        end
        _print_dd_csv(dd_id, dddp)
      end

    else
      dddp = find_dddp(dd_id, ddf)
      _print_dd_csv(dd_id, dddp)
    end
  end

  ## Function attempts to find the datapoint corresponding to the option text  #{{{2
  ## Returns the *first* one found or creates a new one and returns that
  def find_dddp(dd_id, listOf_ddf)
    listOf_ddf.each do |d|
      dddp = DesignDetailDataPoint.find_by_design_detail_field_id_and_study_id_and_extraction_form_id(dd_id,
                                                                                                      @study_id,
                                                                                                      @ef_id)
      unless dddp.blank?
        return dddp
      end
    end

    dddp = DesignDetailDataPoint.new(design_detail_field_id: dd_id,
                                     study_id: @study_id,
                                     extraction_form_id: @ef_id,
                                     row_field_id: 0,
                                     column_field_id: 0,
                                     arm_id: 0,
                                     outcome_id: 0)
    return dddp
  end

  def find_dddp_matrix_checkbox(dd_id, ddf_rows, ddf_cols)  #{{{2
    ddf_rows.each do |row|
      if row.row_number == -1
        ## This is for that optional 'other' row
        dddp = DesignDetailDataPoint.find_by_design_detail_field_id_and_study_id_and_extraction_form_id_and_row_field_id(dd_id,
                                                                                                                        @study_id,
                                                                                                                        @ef_id,
                                                                                                                        row.id)
        if dddp.blank?
          dddp = DesignDetailDataPoint.new(design_detail_field_id: dd_id,
                                           study_id: @study_id,
                                           extraction_form_id: @ef_id,
                                           row_field_id: row.id,
                                           arm_id: 0,
                                           outcome_id: 0)
        end

        _print_dd_csv(dd_id, dddp)
      else
        ddf_cols.each do |col|
          dddp = DesignDetailDataPoint.find_by_design_detail_field_id_and_value_and_study_id_and_extraction_form_id_and_row_field_id(dd_id,
                                                                                                                                     col.option_text,
                                                                                                                                     @study_id,
                                                                                                                                     @ef_id,
                                                                                                                                     row.id)
          _print_dd_csv(dd_id, dddp) unless dddp.blank?
        end

        # We need to check that the correct number of datapoints exist in the database.
        # To do this we look at the total number of entries in the datapoint table for a
        # particular row_field_id. If the number of entries is less than the number
        # of columns then we create a blank row in the csv but we do not create an entry
        # in the database.
        _create_blank_rows("DesignDetail", dd_id, row.id, ddf_cols)
      end
    end
  end

  def _create_blank_rows(section, dd_id, row_field_id, ddf_cols)  #{{{2
    nbr_of_dp_already_in_db = "#{section}DataPoint".constantize.find(:all, :conditions => { design_detail_field_id: dd_id,
                                                                                            study_id:               @study_id,
                                                                                            extraction_form_id:     @ef_id,
                                                                                            row_field_id:           row_field_id,
                                                                                            column_field_id:        0,
                                                                                            arm_id:                 0,
                                                                                            outcome_id:             0 }).length
    nbr_of_dp_needed = ddf_cols.length

    nbr_of_entries_to_create = nbr_of_dp_needed - nbr_of_dp_already_in_db

    if nbr_of_entries_to_create > 0
      nbr_of_entries_to_create.times do |c|
        dddp = DesignDetailDataPoint.new(design_detail_field_id: dd_id,
                                         study_id: @study_id,
                                         extraction_form_id: @ef_id,
                                         row_field_id: row_field_id,
                                         column_field_id: 0,
                                         arm_id: 0,
                                         outcome_id: 0)
        _print_dd_csv(dd_id, dddp)
      end
    end
  end

  ## Will iterate through each matrix cell and try to find a corresponding data point entry  #{{{2
  ## Will return the match or create a new data point if it cannot find one
  def find_dddp_matrix_select(dd_id, ddf_rows, ddf_cols)
    ddf_rows.each do |row|
      if row.row_number == -1
        dddp = DesignDetailDataPoint.find_by_design_detail_field_id_and_study_id_and_extraction_form_id_and_row_field_id(dd_id,
                                                                                                                         @study_id,
                                                                                                                         @ef_id,
                                                                                                                         row.id)
        if dddp.blank?
          dddp = DesignDetailDataPoint.new(design_detail_field_id: dd_id,
                                           study_id: @study_id,
                                           extraction_form_id: @ef_id,
                                           row_field_id: row.id,
                                           column_field_id: 0,
                                           arm_id: 0,
                                           outcome_id: 0)
        end
  
        _print_dd_csv(dd_id, dddp)
      else
        ddf_cols.each do |col|
          listOf_dropdown_options = _find_lof_matrix_select_dropdown_options("DesignDetail", row.id, col.id)
          dddp = DesignDetailDataPoint.find_by_design_detail_field_id_and_study_id_and_extraction_form_id_and_row_field_id_and_column_field_id(dd_id,
                                                                                                                                               @study_id,
                                                                                                                                               @ef_id,
                                                                                                                                               row.id,
                                                                                                                                               col.id)
          if dddp.blank?
            dddp = DesignDetailDataPoint.new(design_detail_field_id: dd_id,
                                             study_id: @study_id,
                                             extraction_form_id: @ef_id,
                                             row_field_id: row.id,
                                             column_field_id: col.id,
                                             arm_id: 0,
                                             outcome_id: 0)
          end
  
          _print_dd_csv(dd_id, dddp)
        end
      end
    end
  end

  def _find_lof_matrix_select_dropdown_options(section, row_id, column_id)  #{{{2
    return MatrixDropdownOption.find(:all, :conditions => { row_id:     row_id,
                                                            column_id:  column_id,
                                                            model_name: "#{section}".underscore })
  end

  ## Will iterate through each matrix cell and try to find a corresponding data point entry  #{{{2
  ## Will return the match or create a new data point if it cannot find one
  def find_dddp_matrix_radio(dd_id, ddf_rows, ddf_cols)
    ddf_rows.each do |row|
      if row.row_number == -1
        dddp = DesignDetailDataPoint.find_by_design_detail_field_id_and_study_id_and_extraction_form_id_and_row_field_id(dd_id,
                                                                                                                         @study_id,
                                                                                                                         @ef_id,
                                                                                                                         row.id)
        if dddp.blank?
          dddp = DesignDetailDataPoint.new(design_detail_field_id: dd_id,
                                           study_id: @study_id,
                                           extraction_form_id: @ef_id,
                                           row_field_id: row.id,
                                           column_field_id: 0,
                                           arm_id: 0,
                                           outcome_id: 0)
        end
  
        _print_dd_csv(dd_id, dddp)
      else
        # Flag to see if there was any choice found for this row
        any_choice_found = false

        ddf_cols.each do |col|
          dddp = DesignDetailDataPoint.find_by_design_detail_field_id_and_value_and_study_id_and_extraction_form_id_and_row_field_id(dd_id,
                                                                                                                                     col.option_text,
                                                                                                                                     @study_id,
                                                                                                                                     @ef_id,
                                                                                                                                     row.id)
          unless dddp.blank?
            any_choice_found = true
            _print_dd_csv(dd_id, dddp)
          end
        end

        if any_choice_found == false
          dddp = DesignDetailDataPoint.new(design_detail_field_id: dd_id,
                                           study_id: @study_id,
                                           extraction_form_id: @ef_id,
                                           row_field_id: row.id,
                                           column_field_id: 0,
                                           arm_id: 0,
                                           outcome_id: 0)
          _print_dd_csv(dd_id, dddp)
        end
      end
    end
  end

  def _print_dd_csv(dd_id, dddp)  #{{{2
    begin
      row_text = DesignDetailField.find(dddp.row_field_id).option_text
    rescue
      row_text = ""
    ensure
    end

    begin
      col_text = DesignDetailField.find(dddp.column_field_id).option_text
    rescue
      col_text = ""
    ensure
    end

    output = ",DesignDetail"\
             ",\"#{_escape_text(DesignDetail.find(dd_id).field_type)}\""\
             ",#{dddp.id}"\
             ",#{dddp.design_detail_field_id}"\
             ",\"#{_escape_text(DesignDetail.find(dd_id).question)}\""\
             ",\"#{_escape_text(dddp.value)}\""\
             ",\"#{_escape_text(dddp.notes)}\""\
             ",#{dddp.study_id}"\
             ",#{dddp.extraction_form_id}"\
             ",\"#{_escape_text(dddp.subquestion_value)}\""\
             ",#{dddp.row_field_id}"\
             ",\"#{_escape_text(row_text)}\""\
             ",#{dddp.column_field_id}"\
             ",\"#{_escape_text(col_text)}\""\
             ",#{dddp.arm_id}"\
             ","\
             ",#{dddp.outcome_id}"\
             ","

    output = "#{common_info}#{output}"
    puts output
  end

  def _print_csv_line(section, dd_id, dddp)  #{{{2
    begin
      row_text = "#{section}Field".constantize.find(dddp.row_field_id).option_text
    rescue
      row_text = ""
    ensure
    end

    begin
      col_text = "#{section}Field".constantize.find(dddp.column_field_id).option_text
    rescue
      col_text = ""
    ensure
    end

    begin
      arm_title = Arm.find(dddp.arm_id).title
    rescue
      arm_title = ""
    ensure
    end

    begin
      outcome_title = Outcome.find(dddp.outcome_id).title
    rescue
      outcome_title = ""
    ensure
    end

    section_field_id_name = "#{section.underscore}_field_id"

    output = ",#{section}"\
             ",\"#{_escape_text("#{section}".constantize.find(dd_id).field_type)}\""\
             ",#{dddp.id}"\
             ",#{dddp.instance_eval(section_field_id_name)}"\
             ",\"#{_escape_text("#{section}".constantize.find(dd_id).question)}\""\
             ",\"#{_escape_text(dddp.value)}\""\
             ",\"#{_escape_text(dddp.notes)}\""\
             ",#{dddp.study_id}"\
             ",#{dddp.extraction_form_id}"\
             ",\"#{_escape_text(dddp.subquestion_value)}\""\
             ",#{dddp.row_field_id}"\
             ",\"#{_escape_text(row_text)}\""\
             ",#{dddp.column_field_id}"\
             ",\"#{_escape_text(col_text)}\""\
             ",#{dddp.arm_id}"\
             ",\"#{_escape_text(arm_title)}\""\
             ",#{dddp.outcome_id}"\
             ",\"#{_escape_text(outcome_title)}\""

    output = "#{common_info}#{output}"
    puts output
  end

  def _escape_text(text)  #{{{2
    begin
      escaped_txt = text.gsub(/"/, '""')
    rescue NoMethodError
      escaped_txt = text
    end

    return escaped_txt
  end
end
























