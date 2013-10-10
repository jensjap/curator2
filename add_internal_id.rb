#encoding: utf-8

require "./lib/environment.rb"
require "csv"

FILE_PATH = "./output/assignments.csv"
PROJECT_ID = 163


def main
  data = CSV.table(FILE_PATH, { :encoding => "ISO8859-1", :col_sep => "\t" })

  data.each do |row|
    pmid = row[:pubmed_id]
    refid = row[:internal_id]

    primary_publications = _find_lof_primary_publications_with_pmid(project_id=PROJECT_ID, pmid=pmid)
    if primary_publications.length == 1
      pp_id = primary_publications[0][:id]
      ppn = _find_primary_publication_number_record_by_primary_publication_id(pp_id)
      ppn.number = refid
      ppn.number_type = "internal"
      ppn.save
    else
      puts "Too many results found for pmid: #{pmid}"
    end
  end
end

def _find_primary_publication_number_record_by_primary_publication_id(pp_id)
  PrimaryPublicationNumber.find_by_primary_publication_id(pp_id)
end

def _find_lof_primary_publications_with_pmid(project_id, pmid)
  PrimaryPublication.find(:all, :conditions => { :pmid => pmid })
end


if __FILE__ == $0

  load_rails_environment
  main()

end
