#encoding: utf-8

require "rubyXL"

require "./lib/environment.rb"
require "./lib/trollop.rb"
require "./lib/section.rb"
require "./lib/worker.rb"

## Minimal arg parser  {{{1
## http://trollop.rubyforge.org/
opts = Trollop::options do
  opt :project_id, "Project ID",                :type => Integer
  opt :option,     "Choices: [export, import]", :type => String
  opt :file,       "File to process",           :type => String
end

## This validates that required parameters have been passed to trollop  {{{1
def validate_arg_list(opts)
  Trollop::die :project_id, "If you are not importing a file, then you must supply a project id" unless opts[:project_id_given] || opts["import-csv"]
end

## Notifies the user of a critical error and quits the program  {{{1
## String -> Exit
def critical(err)
  puts err
  exit
end

## Builds a dictionary with project information for consumption later  {{{1
## (Project ID) -> (Dictionary of Project Information)
def get_project_info(project_id)
  begin
    project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound => err
    critical err
  else
    project_info = Hash.new
    project_info[:project_id]     = project_id
    project_info[:title]          = project.title
    project_info[:description]    = project.description
    project_info[:notes]          = project.notes
    project_info[:funding_source] = project.funding_source
    project_info[:creator_id]     = project.creator_id
    begin
      creator = User.find(project.creator_id)
    rescue ActiveRecord::RecordNotFound => err
      puts "WARNING: #{err}"
      puts "WARNING: project_info:creator field left blank"
      project_info[:creator]      = ""
    else
      project_info[:creator]      = "#{creator.lname}, #{creator.fname}"
    end
    project_info[:is_public]      = project.is_public
    project_info[:created_at]     = project.created_at
    project_info[:updated_at]     = project.updated_at
    project_info[:contributors]   = project.contributors
    project_info[:methodology]    = project.methodology
  end

  return project_info
end

## Puts together a list of extraction form IDs associated with the given project ID  {{{1
## Integer -> (listOf ExtractionFormIDs)
def get_extraction_form_ids(project_id)
  listOfefIDs = Array.new
  extraction_forms = ExtractionForm.find_all_by_project_id(project_id)
  extraction_forms.each do |ef|
    listOfefIDs.push(ef.id)
  end
  return listOfefIDs
end

## Puts together a list of study IDs that are associated with the given extraction form ID  #{{{1
## Integer -> (listOf StudyIDs)
def get_listOfStudyIDs_by_efIDs(ef_id)
  listOfStudyIDs = Array.new

  study_extraction_forms = StudyExtractionForm.find_all_by_extraction_form_id(ef_id)
  study_extraction_forms.each do |s|
    listOfStudyIDs.push s.study_id
  end
  return listOfStudyIDs
end


if __FILE__ == $0  # {{{1
  ## Set up some global variables
  ERRORS = Array.new

  ## Validate trollop arguments passed
  validate_arg_list(opts)

  ## Constants
  PROJECT_ID = opts[:project_id]

  ## Variable decleration
  ef_list = Array.new

  ## Load rails environment so we have access to ActiveRecord
  load_rails_environment

  ## Gather some project information
  project_info = get_project_info(PROJECT_ID)

  if opts[:option] == "export"
    ## First we find a list of extraction form IDs associated with this project
    listOfefIDs = get_extraction_form_ids(PROJECT_ID)
  
    ## Find list of study IDs associated with each extraction form
    listOfefIDs.each do |ef_id|
#    puts "Extraction Form IDs in this project: #{ef_id}"
      puts "Project_ID"\
           ",EF_ID"\
           ",EF_Title"\
           ",Study_ID"\
           ",PrimaryPublication_ID"\
           ",PrimaryPublication_Title"\
           ",PrimaryPublication_Author"\
           ",PrimaryPublication_Country"\
           ",PrimaryPublication_Year"\
           ",PrimaryPublication_PMID"\
           ",PrimaryPublication_Journal"\
           ",PrimaryPublication_Volume"\
           ",PrimaryPublication_Issue"\
           ",PrimaryPublication_Trial_Title"\
           ",PrimaryPublicationNumber_ID"\
           ",PrimaryPublicationNumber_Number"\
           ",PrimaryPublicationNumber_Number_Type"\
           ",Section"\
           ",Type"\
           ",DataPoint_ID"\
           ",Details_ID"\
           ",Question"\
           ",***VALUE"\
           ",***Notes"\
           ",Study_ID"\
           ",EF_ID"\
           ",***Subquestion"\
           ",Row_Field_ID"\
           ",Row_Text"\
           ",Col_Field_ID"\
           ",Col_text"\
           ",Arm_ID"\
           ",Arm_Title"\
           ",Outcome_ID"\
           ",Outcome_Title"
      listOfStudyIDs = get_listOfStudyIDs_by_efIDs(ef_id)
      listOfStudyIDs.each do |study_id|

        ######################################
        study = MyStudy.new(PROJECT_ID, project_info, ef_id, study_id)
        study.print_main

      end
    end

  elsif opts[:option] == "import"
    if opts[:file].blank?
      puts "You have not specified a file name. Program terminating"
    else
      workerbee = Importer.new(opts[:file])
      workerbee.main
      workerbee.sort
      workerbee.process_design_details
      workerbee.process_arms
      workerbee.process_arm_details
      workerbee.process_baseline_characteristics
    end
  end
end













